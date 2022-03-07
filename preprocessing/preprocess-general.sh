#!/bin/bash
#
# Preprocess data.
#
# Dependencies (versions):
# - SCT (5.4.0)
#
# Usage:
# sct_run_batch -script preprocess_data.sh -path-data <PATH-TO-DATASET> -path-output <PATH-TO-OUTPUT> -jobs <num-cpu-cores>

# The following global variables are retrieved from the caller sct_run_batch
# but could be overwritten by uncommenting the lines below:
# PATH_DATA_PROCESSED="~/data_processed"
# PATH_RESULTS="~/results"
# PATH_LOG="~/log"
# PATH_QC="~/qc"

# Uncomment for full verbose
set -x

# Immediately exit if error
set -e -o pipefail

# Exit if user presses CTRL+C (Linux) or CMD+C (OSX)
trap "echo Caught Keyboard Interrupt within script. Exiting now.; exit" INT


# CONVENIENCE FUNCTIONS
# ======================================================================================================================

get_centerline() {
  ###
  # This function returns the output of the sct_get_centerline function applied to a scan
  ###

  local file="$1"
  local contrast="$2"
  # Update global variable with segmentation file name
  FILESEG="${file}_centerline"
  # Get centerline of spinal cord
  sct_get_centerline -i ${file}.nii.gz -c $contrast -qc ${PATH_QC} -qc-subject ${SUBJECT}
}

# Retrieve input params and other params
SUBJECT=$1

# get starting time:
start=`date +%s`


# SCRIPT STARTS HERE
# ==============================================================================
# Display useful info for the log, such as SCT version, RAM and CPU cores available
sct_check_dependencies -short

# Go to folder where data will be copied and processed
cd $PATH_DATA_PROCESSED

# Copy BIDS-required files to processed data folder (e.g. list of participants)
if [[ ! -f "participants.tsv" ]]; then
  rsync -avzh $PATH_DATA/participants.tsv .
fi
if [[ ! -f "participants.json" ]]; then
  rsync -avzh $PATH_DATA/participants.json .
fi
if [[ ! -f "dataset_description.json" ]]; then
  rsync -avzh $PATH_DATA/dataset_description.json .
fi
if [[ ! -f "README" ]]; then
  rsync -avzh $PATH_DATA/README.* .
fi

# Copy source images
# Note: we use '/./' in order to include the sub-folder 'ses-0X'
rsync -Ravzh $PATH_DATA/./$SUBJECT .

# Go to subject folder for source images
cd ${SUBJECT}/anat

# Define variables
# We do a substitution '/' --> '_' in case there is a subfolder 'ses-0X/'
#file="${SUBJECT//[\/]/_}"
file="${SUBJECT//[\/]//}"

# Add suffix corresponding to contrast
file=${file}_T2w

# Make sure the image metadata is a valid JSON object
if [[ ! -s ${file}.json ]]; then
  echo "{}" >> ${file}.json
fi

# Centerline extraction using the T2w contrast
get_centerline ${file} t2
file_seg="${FILESEG}"

# Create mask spinal cord mask
sct_create_mask -i ${file}.nii.gz -p centerline,${file_seg}.nii.gz

# Use mask to crop the original image 
sct_crop_image -i ${file}.nii.gz -m mask_${file}.nii.gz -o ${file}_crop.nii.gz

# Isotropic 0.5mm resampling
sct_resample -i ${file}_crop.nii.gz -mm 0.5x0.5x0.5 -o ${file}_crop_resampled.nii.gz

# Go back to the root output path
cd $PATH_OUTPUT

# Create and populate clean data processed folder to remove clutter
PATH_DATA_PROCESSED_CLEAN="${PATH_DATA_PROCESSED}_clean"

# Copy over required BIDs files
mkdir -p $PATH_DATA_PROCESSED_CLEAN $PATH_DATA_PROCESSED_CLEAN/${SUBJECT} $PATH_DATA_PROCESSED_CLEAN/${SUBJECT}/anat
rsync -avzh $PATH_DATA_PROCESSED/dataset_description.json $PATH_DATA_PROCESSED_CLEAN/
rsync -avzh $PATH_DATA_PROCESSED/participants.* $PATH_DATA_PROCESSED_CLEAN/
rsync -avzh $PATH_DATA_PROCESSED/README.* $PATH_DATA_PROCESSED_CLEAN/

# Copy resampled crops to use as inputs and lumbar cord annotations as targets
rsync -avzh $PATH_DATA_PROCESSED/${SUBJECT}/anat/${file}_crop_resampled.nii.gz $PATH_DATA_PROCESSED_CLEAN/${SUBJECT}/anat/${file}.nii.gz
rsync -avzh $PATH_DATA_PROCESSED/${SUBJECT}/anat/${file}.json $PATH_DATA_PROCESSED_CLEAN/${SUBJECT}/anat/${file}.json

end=`date +%s`
runtime=$((end-start))
echo
echo "~~~"
echo "SCT version: `sct_version`"
echo "Ran on:      `uname -nsr`"
echo "Duration:    $(($runtime / 3600))hrs $((($runtime / 60) % 60))min $(($runtime % 60))sec"
echo "~~~"