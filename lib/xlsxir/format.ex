defmodule Xlsxir.Format do
  
  @moduledoc """
  Receive a parsed excel worksheet in the form of a map:

    %{ 'row_num' => %{ 'cell' => [ 
      's' for string or nil, 
      '1' for date or nil,
      excel function or nil,
      value or reference to sharedStrings 
      ]}, ... }

  Example:

    %{ '1' =>                                 // row 1
      %{ 'A1' => [ 's', nil, nil, '0']},      // cell A1 which contains the string in position '0' 
                                              //   of sharedStrings.xml
      %{ 'B1' => [ nil, nil, '4*5', '20']},   // cell B1 which contains a function with a value of '20'
      %{ 'C1' => [ nil, '1', nil, '41014']}   // cell C1 which contains the Excel date serial number 
                                              //   of '41014'
    }

    Xlsxir.Format formats the cell values and returns the data in either a list or a map depending 
    on the option chosen. 
  """

  def do_format(worksheet, shared_strings, option) do
    
  end

  @doc """
    Formats parsed excel worksheet into a list of lists containing cell values by 
    row (i.e. [[row_1_values], [row_2_values], ...]).
  """
  def row_list do
    
  end

  @doc """
    Formats parsed excel worksheet into a map of cell/value pairs (i.e. %{"A1" => 
    value_of_cell, ...}).
  """
  def cell_map do
    
  end

  @spec format_cell_value(list, list) :: String.t | integer
  def format_cell_value(list, strings) do
    case list do
      ['s', _, _, n] -> Enum.at(strings, n)
      _              -> "Error"
    end
  end

end