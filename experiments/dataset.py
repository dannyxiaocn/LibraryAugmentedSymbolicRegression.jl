import csv

from experiments.srsd import (
    dataset_easy,
    dataset_hard,
    dataset_medium,
    hints_easy,
    hints_hard,
    hints_medium,
)
from experiments.utils import load_json, sample_dataset


def feynman_equations(dataset_path, skip_equations: set = None):
    dataset = []
    with open(dataset_path) as file_obj:
        heading = next(file_obj)
        reader_obj = csv.reader(file_obj)
        for row in reader_obj:
            if row[1] == "":
                break

            id = int(row[1])
            if id in skip_equations:
                continue

            output = row[2]
            formula = row[3]
            num_vars = (row.index("") - 5) // 3

            bounds = {output: None}
            for i in range(num_vars):
                var_name = row[5 + (3 * i)]
                var_bounds = (int(row[6 + (3 * i)]), int(row[7 + (3 * i)]))
                var_sample = "uniform"
                bounds[var_name] = (var_sample, var_bounds)

            dataset.append((id, (output + " = " + formula, bounds)))

    dataset.sort()
    return dataset


def feynman_dataset(
    dataset_path,
    equations_to_keep,
    num_samples,
    noise,
    use_hints=False,
    hints_path=None,
):
    equations = feynman_equations(
        dataset_path, skip_equations=set(range(1, 101)) - equations_to_keep
    )
    all_hints = load_json(hints_path) if use_hints else None
    add_extra_vars = False
    dataset = sample_dataset(equations, num_samples, noise, add_extra_vars)
    return dataset, all_hints


def synthetic_equations(dataset_path):
    dataset = []
    with open(dataset_path) as file_obj:
        heading = next(file_obj)
        reader_obj = csv.reader(file_obj)
        for row in reader_obj:
            if row[1] == "":
                break
            id = int(row[1])
            output = row[2]
            formula = row[3]
            num_vars = (row.index("") - 5) // 3
            bounds = {output: None}
            for i in range(num_vars):
                var_name = row[5 + (3 * i)]
                var_bounds = (int(row[6 + (3 * i)]), int(row[7 + (3 * i)]))
                var_sample = "uniform"
                bounds[var_name] = (var_sample, var_bounds)
            dataset.append((id, (output + " = " + formula, bounds)))
    dataset.sort()
    return dataset


def synthetic_dataset(num_samples, noise, dataset_path="data/synthetic_equations.csv", hints_path="data/synthetic_hints.json", use_hints=True):
    equations = synthetic_equations(dataset_path)
    all_hints = load_json(hints_path) if use_hints else None
    add_extra_vars = False
    dataset = sample_dataset(equations, num_samples, noise, add_extra_vars)
    return dataset, all_hints


def srsd_equations():
    datasets = {
        "Easy SRSD": (dataset_easy, hints_easy),
        "Medium SRSD": (dataset_medium, hints_medium),
        "Hard SRSD": (dataset_hard, hints_hard),
    }
    dataset_order = ["Hard SRSD", "Medium SRSD", "Easy SRSD"]
    return datasets, dataset_order


def srsd_dataset(equations_order, num_samples, noise, use_hints=False, hints_path=None):
    equations, _ = srsd_equations()
    equations = equations[equations_order][0]
    all_hints = equations[equations_order][1] if use_hints else None
    dataset = sample_dataset(equations, num_samples, noise, add_extra_vars=True)
    return dataset, all_hints
