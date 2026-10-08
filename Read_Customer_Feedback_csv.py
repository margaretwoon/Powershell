import pandas as pd

# Load the Excel file
file_path = r"C:\Users\miw\OneDrive - Great Southern Bank\Documents\py3\DataProgram\prime_search_RPT_14012025.xlsx"

# Specify the sheet name and column name
sheet_name = 'Search Results'
column_name = 'RPT'

# Read the specific sheet
df = pd.read_excel(file_path, sheet_name=sheet_name)

# Extract the specific column
column_data = df[column_name]

# Filter the column data to include only rows containing 'RPT'
filtered_data = column_data[column_data.str.contains('RPT', na=False)]

# Display the column data
print(column_data)


# Replace newline characters with spaces
filtered_data = filtered_data.str.replace('\n', '  ')

# Display the column data
print(filtered_data)

df['filtered_data'] = filtered_data

# Specify the row indices to filter
row_indices = [14,15,16,17,18,19,20,117,119,120,121,122,128,132,165,166]

# Filter the DataFrame to include only the specified rows
filtered_df = df.iloc[row_indices]

# Display the filtered DataFrame
print(filtered_df)

# Specify the output file path
output_file_path = 'prime_search_file_filtered.csv'

# Output the DataFrame to a CSV file
filtered_df.to_csv(output_file_path, index=True)