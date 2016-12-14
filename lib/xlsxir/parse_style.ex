defmodule Xlsxir.ParseStyle do
  alias Xlsxir.Index
  alias Xlsxir.Style

  @moduledoc """
  Holds the SAX event instructions for parsing style data via `Xlsxir.SaxParser.parse/2`
  """

  # the following module attributes hold `numStyleId`s for standard number styles, grouping them between numbers and dates
  @num  [0,1,2,3,4,9,10,11,12,13,37,38,39,40,44,48,49,59,60,61,62,67,68,69,70]
  @date [14,15,16,17,18,19,20,21,22,27,30,36,45,46,47,50,57]

  defstruct custom_style: %{}, cellxfs: false

  @doc """
  Sax event utilized by `Xlsxir.SaxParser.parse/2`. Takes a pattern and the current state of a struct and recursivly parses the
  styles XML file, ultimately sending each parsed style type to the `Xlsxir.Style` module which contains an ETS process that was started by 
  `Xlsxir.SaxParser.parse/2`. The style types generated are `nil` for numbers and `'d'` for dates. 

  ## Parameters

  - pattern - the XML pattern of the event to match upon
  - state - the state of the `%Xlsxir.ParseStyle{}` struct which temporarily holds each `numFmtId` and its associated `formatCode` for custom format types

  ## Example
  Recursively sends style types generated from parsing the `xl/sharedStrings.xml` file to `Style.add_style/1`. The data can ultimately
  be retreived by the `get_at/1` function of the `Xlsxir.Style` module (i.e. `Xlsxir.Style.get_at(0)` would return `nil` or `'d'` depending on each style type generated).
  """
  def sax_event_handler(:startDocument, _state) do 
    Index.new
    %Xlsxir.ParseStyle{}
  end

  def sax_event_handler({:startElement,_,'cellXfs',_,_}, state) do
    %{state | cellxfs: true}
  end

  def sax_event_handler({:endElement,_,'cellXfs',_}, state) do
    %{state | cellxfs: false}
  end

  def sax_event_handler({:startElement,_,'xf',_,xml_attr}, state) do
    if state.cellxfs do
      [{_,_,_,_,id}] = Enum.filter(xml_attr, fn attr -> 
                         case attr do 
                           {:attribute,'numFmtId',_,_,_} -> true
                           _                             -> false
                         end  
                       end)

      Style.add_id(id)
    end
    
    state
  end

  def sax_event_handler({:startElement,_,'numFmt',_,xml_attr}, 
    %Xlsxir.ParseStyle{custom_style: custom_style} = state) do
    
    temp = Enum.reduce(xml_attr, %{}, fn attr, acc -> 
            case attr do
              {:attribute,'numFmtId',_,_,id}   -> Map.put(acc, :id, id)
              {:attribute,'formatCode',_,_,cd} -> Map.put(acc, :cd, cd)
              _                                -> nil
            end
          end)

    %{state | custom_style: Map.put(custom_style, temp[:id], temp[:cd])}
  end

  def sax_event_handler(:endDocument, %Xlsxir.ParseStyle{custom_style: custom_style}) do

    custom_type = custom_style_handler(custom_style)

    Enum.each(Style.get_id, fn style_type -> 
      case List.to_integer(style_type) do
        i when i in @num   -> Style.add_style(nil, Index.get)
        i when i in @date  -> Style.add_style('d', Index.get)
        _                  -> add_custom_style(style_type, custom_type)
      end

      Index.increment_1
    end)

    Style.delete_id
    Index.delete
  end

  def sax_event_handler(_, state), do: state

  defp custom_style_handler(custom_style) do
    custom_style
    |> Enum.reduce(%{}, fn {k, v}, acc -> 
         cond do
           String.match?(to_string(v), ~r/\bred\b/i) -> Map.put_new(acc, k, nil)
           String.match?(to_string(v), ~r/[dhmsy]/i) -> Map.put_new(acc, k, 'd')
           true                                      -> Map.put_new(acc, k, nil)
         end
      end)
  end

  defp add_custom_style(style_type, custom_type) do
    if Map.has_key?(custom_type, style_type) do
      Style.add_style(custom_type[style_type], Index.get)
    else
      raise "Unsupported style type: #{style_type}. See doc page \"Number Styles\" for more info."
    end
  end

end
