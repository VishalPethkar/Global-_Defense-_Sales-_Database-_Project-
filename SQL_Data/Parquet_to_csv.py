import pandas as pd

folder = r"D:\download\Global_Defense_Sales_Data_500K"
df = pd.read_excel(folder + r"\Global_Defense_Sales_Data_500K.xlsx")   # apni file ka exact naam likho
df.to_csv(folder + r"\sales.csv", index=False, date_format="%Y-%m-%d")
print(df.shape)   # (500000, 18) aana chahiye