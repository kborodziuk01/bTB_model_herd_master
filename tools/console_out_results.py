import csv
import os

import matplotlib.pyplot as plt
import numpy as np
import shutil

output_dir = "output_max"
os.makedirs(output_dir, exist_ok=True)

def save_csv_files(data,outdir):
    for label, values in data.items():
        label_dir = os.path.join(outdir, label)
        os.makedirs(label_dir, exist_ok=True)

        csv_file_path = os.path.join(label_dir, "table.csv")

        sorted_keys = sorted(values.keys(), key=int)
        with open(csv_file_path, mode="w", newline="") as csvfile:
            writer = csv.writer(csvfile)
            writer.writerow(["Key", "Value[0]", "Value[1]", "Value[2]"])
            for key in sorted_keys:
                writer.writerow([key] + values[key])


def create_graphs(data,outdir):
    for label, values in data.items():
        label_dir = os.path.join(outdir, label)
        os.makedirs(label_dir, exist_ok=True)

        sorted_items = sorted(values.items(), key=lambda x: int(x[0]))
        x = [int(key) for key, _ in sorted_items]
        y_values = list(zip(*[value for _, value in sorted_items]))

        for i in range(3):
            plt.figure()
            plt.plot(x, y_values[i], marker='o', label=f"Value[{i}]")
            plt.xlabel("Key")
            plt.ylabel(f"Value[{i}]")
            plt.title(f"{label} - Graph {i + 1}")
            plt.legend()
            plt.grid(True)

            graph_file_path = os.path.join(label_dir, f"graph_{i + 1}.png")
            plt.savefig(graph_file_path)
            plt.close()

def calculate_max(transformed_data):
    median_data = {}

    for label, data in transformed_data.items():
        median_structure = {}
        for key, values in data.items():
            values_array = np.array(values, dtype=float)
            medians = np.max(values_array, axis=0).tolist()
            median_structure[key] = medians

        median_data[label] = median_structure

    return median_data

def calculate_median(transformed_data):
    median_data = {}

    for label, data in transformed_data.items():
        median_structure = {}
        for key, values in data.items():
            values_array = np.array(values, dtype=float)
            medians = np.median(values_array, axis=0).tolist()
            median_structure[key] = medians

        median_data[label] = median_structure

    return median_data

def calculate_mean(transformed_data):
    median_data = {}

    for label, data in transformed_data.items():
        median_structure = {}
        for key, values in data.items():
            values_array = np.array(values, dtype=float)
            medians = np.mean(values_array, axis=0).tolist()
            median_structure[key] = medians

        median_data[label] = median_structure

    return median_data


def chunk_and_relabel(data, chunk_size=20, labels_cycle=("mb_4", "mb_5", "mb_6")):
    chunks = [data[i:i + chunk_size] for i in range(0, len(data), chunk_size)]
    updated_data = []


    for idx, chunk in enumerate(chunks):
        new_label_suffix = labels_cycle[idx % len(labels_cycle)]
        for row in chunk:
            row[0] = f"{row[0]}_{new_label_suffix}"
            updated_data.append(row)

    return updated_data


###
### specify the path to netlogo output file generated with the write_rep function at the end of a run or runs.
### normally I use the netlogo behaviour space to run some experiments, each run then adds a new record to the txt results file.
### some extra manipulation might be required. i normally use n++ to quickly format the file, by removing the quotation marks
### and by adding line breaks between different runs.  this will then output 3 directories with graphs and tables for each run
### in the text file.
###


f = "model/run1/run1_test_res.txt"

with open(f,"r") as file:
    res = file.readlines()

processed_res = []

for x in range(len(res)):
    a = res[x].split("[")
    a = [x for x in a if x != ""]
    a = [x.replace("]", "").strip().replace(" ", ",").split(',') for x in a]
    a[0] = a[0][0]
    processed_res.append(a)

processed_res_relabelled = chunk_and_relabel(processed_res)

label_to_data = {}

for row in processed_res_relabelled:
    label = row[0]
    data_points = row[1:]
    if label not in label_to_data:
        label_to_data[label] = []
    label_to_data[label].append(data_points)

transformed_data = {}

for label, rows in label_to_data.items():
    unique_keys = {item[0] for row in rows for item in row}
    new_structure = {key: [] for key in unique_keys}


    for row in rows:
        for item in row:
            key = item[0]
            value = item[1:]
            new_structure[key].append(value)


    transformed_data[label] = new_structure

median_based_dict = calculate_median(transformed_data)
mean_based_dict = calculate_mean(transformed_data)
max_based_dict = calculate_max(transformed_data)

save_csv_files(median_based_dict,"2020_2024_new/output_median")
save_csv_files(mean_based_dict,"2020_2024_new/output_mean")
save_csv_files(max_based_dict,"2020_2024_new/output_max")
create_graphs(median_based_dict,"2020_2024_new/output_median")
create_graphs(mean_based_dict,"2020_2024_new/output_mean")
create_graphs(max_based_dict,"2020_2024_new/output_max")

def move_to_1(outdir):

    all_graphs_dir = os.path.join(outdir, "all_graphs")
    os.makedirs(all_graphs_dir, exist_ok=True)


    for label_dir in os.listdir(outdir):
        label_path = os.path.join(outdir, label_dir)
        if os.path.isdir(label_path):
            graph_3_path = os.path.join(label_path, "graph_3.png")
            if os.path.exists(graph_3_path):
                shutil.copy(graph_3_path, os.path.join(all_graphs_dir, f"{label_dir}_graph_3.png"))



move_to_1("2020_2024_new/output_median")
move_to_1("2020_2024_new/output_mean")
move_to_1("2020_2024_new/output_max")

