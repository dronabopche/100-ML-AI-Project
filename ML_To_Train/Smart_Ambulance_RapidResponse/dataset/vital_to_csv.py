import vitaldb
import pandas as pd

VITAL_FILE_PATH = "/Users/dronabopche/Documents/xcode /100-ML::AL-Project/ML_To_Train/Smart_Ambulance_RapidResponse/dataset/0001.vital"
CSV_OUTPUT_PATH = "/Users/dronabopche/Documents/xcode /100-ML::AL-Project/ML_To_Train/Smart_Ambulance_RapidResponse/dataset/0001.csv"

vf = vitaldb.VitalFile(VITAL_FILE_PATH)

tnames = vf.get_track_names()

print("AVAILABLE TRACKS IN THIS FILE:")

for t in tnames:
    print(t)


ttnames = ['Solar8000/HR','Solar8000/ART_SBP','Solar8000/ART_DBP','Solar8000/PLETH_SPO2','SNUADC/PLETH']

df = vf.to_pandas(ttnames, interval=1)

df = df.reset_index()

# Rename index column to time_sec (optional)
if df.columns[0] == "index":
    df = df.rename(columns={"index": "time_sec"})


df.to_csv(CSV_OUTPUT_PATH, index=False)

print("\n✅ Saved CSV successfully at:")
print(CSV_OUTPUT_PATH)
