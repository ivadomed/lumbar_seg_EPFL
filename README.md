# lumbar_seg_EPFL
Model repository for lumbar spinal cord segmentation from EPFL data.

## Context and objective
Sciatica or hernias in the lumbar spinal cord can cause severe chronic pain. Researchers at EPFL, in Switzerland, shared with our laboratory MRI images of the lumbar marrow of participants, as well as manual segmentations made by experts.

Here, we aim to train a lumbar spinal cord segmentation model on these MRI images and make the model accessible via open-source software to enable global use.

## Data
This dataset was shared by Nawal Kinany <nawal.kinany@epfl.ch> and Dimitry Van De Ville <dimitri.vandevill@epfl.ch>, from EPFL.

This dataset contains images of the lumbar spinal cord with T2w contrast.

## Access to the data
git@data.neuro.polymtl.ca:datasets/lumbar-epfl

# Getting started

## Dependencies
- [SCT](https://spinalcordtoolbox.com/) commit: git-master-7c4f081a0cb566fd8f4702a7e0f8b43bcb02b412
- [ivadomed](https://ivadomed.org) commit: git-master-97b5772374660b12895f7a458941f468090e8bf8

## Preprocess the data
The data need to be preprocessed before training. This will reorient the images to a common orientation (LPI) and resample them. To run the script, run the following command

  ```
  sct_run_batch -script <PATH_TO_REPOSITORY>/preprocess/preprocess_data.sh -path-data <PATH_TO_DATA>/lumbar_epfl/ -path-output <PATH_OUTPUTS>/lumbar_epfl_preprocessed -jobs <JOBS>
  ```

Where:
- `<JOBS>`: Number of CPU cores to use (we recommend not using more than half the number of available cores.)


## Training

The training task is carried out using the clean preprocessed dataset using the command
  ```
  ivadomed --train -c config.json --path-data path/to/bids/data --path-output path/to/output/directory
  ```
## Testing 
Testing a lumbar cord segmentation is done using the command

```
ivadomed --test -c config.json --path-data path/to/bids/data --path-output path/to/output/directory
```

## Segment a dataset
In order to segment a dataset, run the following command

```
ivadomed --segment -c config.json --path-data path/to/bids/data --path-output path/to/output/directory
```
