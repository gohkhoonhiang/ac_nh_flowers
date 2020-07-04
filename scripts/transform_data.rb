require 'json'
require 'csv'

InvalidFileFormat = Class.new(StandardError)

def write_to_file(input, output)
  formatted_data = format_data(input)

  File.write(output, { data: formatted_data }.to_json)
end

# example
# Raw data:
# Type,Gene,Color,Name,Parent 1,Parent 2,Chance
# Roses,RR-yy-WW-Ss,Red,Seed red,-,-,-
#
# will be converted to:
# Formatted data: {"type"=>"Roses", "gene"=>{"code"=>"RR-yy-WW-Ss", "alleles"=>{"red"=>["R","R"], "yellow"=>["y","y"], "white"=>["W","W"], "shade"=>["S","s"]}}, "color"=>"Red", "name"=>"Seed red", "parent_1"=>nil, "parent_2"=>nil, "chance"=>nil}
#
# Raw data:
# Type,Gene,Color,Name,Parent 1,Parent 2,Chance
# Roses,Rr-Yy-WW-ss,Orange,Orange,RR-yy-WW-Ss,rr-YY-WW-ss,0.5
#
# will be converted to:
# Formatted data: {"type"=>"Roses", "gene"=>{"code"=>"Rr-Yy-WW-ss", "alleles"=>{"red"=>["R","r"], "yellow"=>["Y","y"], "white"=>["W","W"], "shade"=>["s","s"]}}, "color"=>"Orange", "name"=>"Orange", "parent_1"=>{"code"=>"RR-yy-WW-Ss", "alleles"=>{"red"=>["R","R"], "yellow"=>["y","y"], "white"=>["W","W"], "shade"=["S","s"]}, "parent_2"=>{"red"=>["r","r"], "yellow"=>["Y","Y"], "white"=>["W","W"], "shade"=>["s","s"]}}, "chance"=>0.5}
def format_data(file_path)
  raise InvalidFileFormat unless File.extname(file_path) == ".csv"

  content = CSV.read(file_path, col_sep: ",", headers: true)
  transformed = content.map do |row|
    row.to_h.transform_keys { |k| snake_case(k) }.transform_values { |v| normalize(v) }
  end

  format_rows(transformed)
end

# example
# Raw data: {"type"=>"Roses", "gene"=>{"code"=>"RR-yy-WW-Ss", "alleles"=>{"red"=>["R","R"], "yellow"=>["y","y"], "white"=>["W","W"], "shade"=>["S","s"]}}, "color"=>"Red", "name"=>"Seed red", "parent_1"=>nil, "parent_2"=>nil, "chance"=>nil}
#
# will be converted to:
# Formatted data: {"key"=>"roses_seed_red_RR-yy-WW-Ss__", "type"=>"Roses", "gene"=>{"code"=>"RR-yy-WW-Ss", "alleles"=>{"red"=>["R","R"], "yellow"=>["y","y"], "white"=>["W","W"], "shade"=>["S","s"]}}, "color"=>"Red", "name"=>"Seed red", "parent_1"=>{}, "parent_2"=>{}, "chance"=>nil}
#
# Raw data: {"type"=>"Roses", "gene"=>{"code"=>"Rr-Yy-WW-ss", "alleles"=>{"red"=>["R","r"], "yellow"=>["Y","y"], "white"=>["W","W"], "shade"=>["s","s"]}}, "color"=>"Orange", "name"=>"Orange", "parent_1"=>{"red"=>["R","R"], "yellow"=>["y","y"], "white"=>["W","W"], "shade"=["S","s"]}, "parent_2"=>{"red"=>["r","r"], "yellow"=>["Y","Y"], "white"=>["W","W"], "shade"=>["s","s"]}, "chance"=>0.5}
#
# will be converted to:
# Formatted data: {"key"=>"roses_orange_Rr-Yy-WW-ss_RR-yy-WW-Ss_rr-YY-WW-ss", "type"=>"Roses", "gene"=>{"code"=>"Rr-Yy-WW-ss", "alleles"=>{"red"=>["R","r"], "yellow"=>["Y","y"], "white"=>["W","W"], "shade"=>["s","s"]}}, "color"=>"Orange", "name"=>"Orange", "parent_1"=>{"name"=>"Red", "gene"=>{"code"=>"RR-yy-WW-Ss", "alleles"=>{"red"=>["R","R"], "yellow"=>["y","y"], "white"=>["W","W"], "shade"=["S","s"]}}}, "parent_2"=>{"name"=>"Yellow", "gene"=>{"code"=>"rr-YY-WW-ss", "alleles"=>{"red"=>["r","r"], "yellow"=>["Y","Y"], "white"=>["W","W"], "shade"=>["s","s"]}}}, "chance"=>0.5}
def format_rows(rows)
  rows.each do |row|
    format_row(rows, row)
  end
  rows
end

def format_row(rows, row)
  if row['parent_1']
    row['parent_1'] = find_parent(rows, row, 'parent_1')
  else
    row['parent_1'] = {}
  end
  if row['parent_2']
    row['parent_2'] = find_parent(rows, row, 'parent_2')
  else
    row['parent_2'] = {}
  end
  row['key'] = "#{snake_case(row['type'])}_#{snake_case(row['name'])}_#{row.dig('gene', 'code')}_#{row.dig('parent_1', 'gene', 'code')}_#{row.dig('parent_2', 'gene', 'code')}"
end

def snake_case(s)
  s.downcase.tr(' ','_')
end

def normalize(s)
  return if s.nil?

  if float?(s)
    s.to_f
  elsif genes?(s)
    normalize_genes(s)
  elsif s == '-'
    nil
  else
    s
  end
end

def float?(s)
  Float(s)
  true
rescue ArgumentError
  false
end

def genes?(s)
  /\w{2}\-/.match?(s)
end

def normalize_genes(s)
  {}.tap do |h|
    h['code'] = s
    pairs = s.split('-')
    h['alleles'] = pairs.inject({}) do |genes, pair|
      genes[gene_type(pair)] = pair.split('')
      genes
    end
  end
end

def gene_type(pair)
  if (/r/i).match?(pair)
    'red'
  elsif (/y/i).match?(pair)
    'yellow'
  elsif (/w/i).match?(pair)
    'white'
  elsif (/o/i).match?(pair)
    'orange'
  else
    'shade'
  end
end

def find_parent(rows, row, parent_key)
  {
    'name' => find_parent_name(rows, row['type'], row[parent_key]),
    'gene' => row[parent_key]
  }
end

def find_parent_name(rows, type, parent)
  same_type = rows.select { |f| f['type'] == type }
  found = same_type.find do |f|
    f.dig('gene', 'code') == parent.dig('code')
  end
  return nil unless found

  found['name']
end
