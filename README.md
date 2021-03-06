# runtime-ds-test

Runtime Data Science using fabric code and cookiecutter

# Project Organization

```
    ├── Makefile            <- Makefile with commands for controlling aspects of the project.
    ├── README.md           <- The top-level README for developers using this project.
    ├── cloud-mle
    │   ├── data            <- Scripts to download, upload or generate data.
    │   ├── scripts         <- Scripts to submit the tasks and deploy model to ML Engine.
    │   ├── <MODEL_NAME>    <- Python code to train and serve the model. For every
    │   │   │                  new model, create a new folder.
    │   │   ├── model.py
    │   │   ├── predict.py
    │   │   └── train.py 
    │
    ├── data
    │   ├── external        <- Data from third party sources.
    │   ├── interim         <- Intermediate data that has been transformed.
    │   ├── processed       <- The final, canonical data sets for modeling.
    │   └── raw             <- The original, immutable data dump.
    │
    ├── docs                <- Place to put extra project-related documents.
    │
    ├── models              <- Trained and serialized models, model predictions, or model summaries.
    │
    ├── notebooks          <- Jupyter notebooks. Naming convention is a number (for ordering),
    │   │                     the creator's initials, and a short `-` delimited description, e.g.
    │   │                      `1.0-jqp-initial-data-exploration`.
    │   ├── exploration    <- Exploration and visualization code to determine hypothesis and 
    │   │                     better understanding the data.
    │   ├── features       <- Features engineering to prepare data to model.
    │   ├── ingestion      <- Data munging modules to read from different data sources/streams, 
    │   │                     transform and load data onto different destinations.
    │   └── models         <- Models proposed and related components, like metrics functions.
    │
    ├── references          <- Data dictionaries, manuals, and all other explanatory materials.
    │
    ├── reports             <- Generated analysis as HTML, PDF, LaTeX, etc.
    │   └── figures         <- Generated graphics and figures to be used in reporting.
    │
    └── services            <- The production services that are to be deployed.
```
