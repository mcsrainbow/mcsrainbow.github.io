#!/bin/bash
# Update LoveIt theme submodule to the latest upstream commit

# Readline library accepts \001 and \002 as non-visible text delimiters
# The bash-specific \[ and \] are translated to \001 and \002
nvt_open=$'\001' # non-visible text open
nvt_close=$'\002' # non-visible text close

# Enable color in terminal with tput and non-visible text delimiters
tput_red=${nvt_open}$(tput setaf 1)${nvt_close}
tput_green=${nvt_open}$(tput setaf 2)${nvt_close}
tput_reset=${nvt_open}$(tput sgr0)${nvt_close}

# Check if there is any pending change in the working directory
if [[ $(git status -s) ]]; then
  echo "${tput_red}ERROR: The working directory is dirty, please commit all pending changes${tput_reset}"
  exit 1
fi

# Update the LoveIt submodule to the latest remote commit
echo "${tput_green}INFO: 1.Updating themes/LoveIt to the latest upstream...${tput_reset}"
git submodule update --remote themes/LoveIt
if [[ $? -ne 0 ]]; then
  echo "${tput_red}ERROR: Failed to update themes/LoveIt${tput_reset}"
  exit 1
fi

# Check if the submodule actually changed
if [[ -z $(git status -s themes/LoveIt) ]]; then
  echo "${tput_green}INFO: 2.themes/LoveIt is already up to date${tput_reset}"
  exit 0
fi

# Stage and commit the updated submodule reference
echo "${tput_green}INFO: 2.Staging and committing the updated submodule...${tput_reset}"
git add themes/LoveIt

if [[ $# -eq 1 ]]; then
  commit_msg="$1"
else
  commit_msg="chore: update LoveIt theme to latest on $(date '+%b %d, %Y')"
fi

git commit -m "$commit_msg"
if [[ $? -ne 0 ]]; then
  echo "${tput_red}ERROR: Failed to commit the submodule update${tput_reset}"
  exit 1
fi

# Done
echo "${tput_green}INFO: 3.Done${tput_reset}"
