defmodule Xlsxir.ParseString do
  alias Xlsxir.Index
  alias Xlsxir.SharedString

  @moduledoc """
  Holds the SAX event instructions for parsing sharedString data via `Xlsxir.SaxParser.parse/2`
  """

  defstruct empty_string: true, family: false, family_string: ""

  @doc """
  Sax event utilized by `Xlsxir.SaxParser.parse/2`. Takes a pattern and the current state of a struct and recursivly parses the
  sharedString XML file, ultimately sending each parsed string to the `Xlsxir.SharedString` module which contains an ETS process started by 
  `Xlsxir.SaxParser.parse/2`. 

  ## Parameters

  - pattern - the XML pattern of the event to match on
  - state - current state of the `%Xlsxir.ParseString{}` struct

  ## Example
  Recursively sends strings from the `xl/sharedStrings.xml` file to `Xlsxir.SharedString.add_shared_string/2`. The data can ultimately
  be retreived by the `get_at/1` function of the `Xlsxir.SharedString` module (i.e. `Xlsxir.SharedString.get_at(0)` would return something like `"string 1"`).
  """
  def sax_event_handler(:startDocument, _state), do: Index.new

  def sax_event_handler({:startElement,_,'si',_,_}, _state), do: %Xlsxir.ParseString{}

  def sax_event_handler({:startElement,_,'family',_,_}, state) do 
    %{state | family: true}
  end

  def sax_event_handler({:characters, value}, 
    %Xlsxir.ParseString{family: family, family_string: fam_str} = state) do
      if family do
        value = value |> to_string
        %{state | family_string: fam_str <> value}
      else
        value
        |> to_string
        |> SharedString.add_shared_string(Index.get)

        Index.increment_1
        %{state | empty_string: false}
      end
  end

  def sax_event_handler({:endElement,_,'si',_}, 
    %Xlsxir.ParseString{empty_string: empty_string, family: family, family_string: fam_str}) do
      cond do
        family       -> SharedString.add_shared_string(fam_str, Index.get)
                        Index.increment_1
        empty_string -> SharedString.add_shared_string("", Index.get)
                        Index.increment_1
        true         -> nil
      end
  end

  def sax_event_handler(:endDocument, _state), do: Index.delete

  def sax_event_handler(_, state), do: state
 
end
