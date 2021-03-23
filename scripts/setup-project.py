#!/usr/bin/env python3
import argparse
import json
import os
import shutil
import subprocess
import uuid
from datetime import datetime
from pathlib import Path
from typing import Dict, Optional

DESCRIPTION = """ This script will attempt to guess the type of project by
reading the current directory and then cache it dependencies dependencies. It
supports Python, Nuxt, Rust as of now. Later, it can be used to build a
project as well. """

STORAGE_DIRECTORY = Path(os.path.expanduser("~/.ephemeral/"))
PROJECT_LOG_FILE = STORAGE_DIRECTORY / "projects.log.json"
# Data will be stored in the `PROJECT_LOG_FILE` in the following format:
# {
#     "/path/to/project": {
#         "id": 12,
#         "slug": "some-random-string",
#         "project_type": "python",
#         "created_on": "3/24/2021, 04:59:31",  // "%m/%d/%Y, %H:%M:%S"
#         "used_on": ["3/24/2021, 04:59:31", "3/27/2021, 14:12:31"]
#     },
#     "/path/to/another/project": {
#         # the above fields with correct data
#     },
# }


def guess_project_type(project_path: Path) -> Optional[str]:
    projects = {
        "python": ["pyproject.toml", "poetry.lock"],
        "javascript": ["package.json", "yarn.lock"],
        "rust": ["Cargo.toml"],
    }
    for project_type, files in projects.items():
        if all(file in os.listdir(project_path) for file in files):
            return project_type
    return None


def check_if_cached(project_path: Path) -> bool:
    """This function will check if the project we are trying to operate on is
    already present in the cache."""

    # first we check if the cache folder exists
    # if it does not, we create it and return False
    if not os.path.isdir(STORAGE_DIRECTORY):
        os.mkdir(STORAGE_DIRECTORY)
        return False

    # next we check if the project file we are looking for exists
    # if it does not, we create it and continue
    if not os.path.isfile(PROJECT_LOG_FILE):
        with open(PROJECT_LOG_FILE, "w") as _:
            return False
    # now we check if the project exists in cache
    with open(PROJECT_LOG_FILE) as file:
        try:
            projects_data = json.load(file)
            return str(project_path.resolve()) in projects_data
        except json.JSONDecodeError:
            # if this error is raised, it must mean that the log file is empty
            return False


def get_default_project_log(project_path: Path, id: int) -> Dict:
    """This generates the default project log which resembles the log file
    format."""
    project_type = guess_project_type(project_path)
    return {
        str(project_path.resolve()): {
            "id": id,
            "slug": str(uuid.uuid4()),
            "project_type": project_type,
            "created_on": datetime.now().strftime("%m/%d/%Y, %H:%M:%S"),
            "used_on": [],
        }
    }


def update_log_file_with_project(project_path: Path) -> None:
    """This function will update the log file with this run. Incase the
    project was not cached, it will update the log file and add the current run."""
    if not os.path.isdir(STORAGE_DIRECTORY):
        os.mkdir(STORAGE_DIRECTORY)
    if not check_if_cached(project_path):
        # the project does not exist in the logs, we need to update it with
        # the correct entry
        try:
            with open(PROJECT_LOG_FILE) as file:
                projects_data = json.load(file)
            # the file has some entries, so we count the number of
            # projects that already exist
            with open(PROJECT_LOG_FILE, "w") as file:
                new_id = len(projects_data) + 1
                projects_data.update(get_default_project_log(project_path, new_id))
                json.dump(projects_data, file, indent=2)
        except (json.JSONDecodeError, FileNotFoundError):
            # this means that though the file exists, it does not have any
            # entries, ie, it is empty
            # this is the first entry in that file
            with open(PROJECT_LOG_FILE, "w") as file:
                json.dump(get_default_project_log(project_path, 1), file, indent=2)
    else:
        # the project exists in the log, we update the `used_on` field
        with open(PROJECT_LOG_FILE) as file:
            projects_data = json.load(file)
            projects_data[str(project_path.resolve())]["used_on"].append(
                datetime.now().strftime("%m/%d/%Y, %H:%M:%S")
            )
        # write to the log file
        with open(PROJECT_LOG_FILE, "w") as file:
            json.dump(projects_data, file, indent=2)


def create_symlink(project_path: Path, directory_name: str):
    """This function will move the cache to the correct directory, and then
    symlink to it accordingly"""
    project_type = guess_project_type(project_path)
    symlink_name = ".venv" if project_type == "python" else "node_modules"
    symlink_target = project_path / symlink_name
    if os.path.islink(symlink_target):
        # we skip the creation of symlinks since they already exist
        return
    directory = STORAGE_DIRECTORY / directory_name
    shutil.move(str(symlink_target), str(directory.resolve() / symlink_name))
    os.symlink(directory.resolve() / symlink_name, project_path / symlink_name)


def get_cache_directory_name(project_path: Path) -> str:
    """This will return the name of the directory where a project's cache
    will be stored"""
    with open(PROJECT_LOG_FILE) as file:
        projects_data = json.load(file)
        return projects_data[str(project_path.resolve())]["slug"]


def get_num_used(project_path: Path) -> int:
    """ This will return the number of times a project was used """
    with open(PROJECT_LOG_FILE) as file:
        projects_data = json.load(file)
        return len(projects_data[str(project_path.resolve())]["used_on"])


def generate_project(project_path: Path, project_type: str) -> None:
    """
    This will handle the following commands:
    1. yarn install
    2. poetry install
    """
    update_log_file_with_project(project_path)
    directory = get_cache_directory_name(project_path)
    if project_type == "python":
        subprocess.check_call(["poetry", "install"])
    elif project_type == "javascript":
        subprocess.call(["yarn", "install"])
    create_symlink(project_path, directory)


def build_project(project_path: Path, project_type: str) -> None:
    """
    This will handle the following commands:
    1. cargo build
    2. yarn generate
    """
    update_log_file_with_project(project_path)
    directory = STORAGE_DIRECTORY / get_cache_directory_name(project_path)
    if project_type == "javascript":
        # delete the build directory in project path if it exists
        src_build_dir = str(directory / "dist")
        dest_build_dir = str(project_path / "dist")
        shutil.rmtree(dest_build_dir, ignore_errors=True)
        # we delete all previous files from the cache except node_modules
        for item in os.listdir(directory):
            if item == "node_modules":
                continue
            try:
                os.remove(directory / item)
            except IsADirectoryError:
                shutil.rmtree(directory / item)
        # now we copy the project contents to cache
        for item in os.listdir(project_path):
            # ignore the node_modules symlink
            if item == "node_modules":
                continue
            if os.path.isdir(item):
                shutil.copytree(str(project_path / item), directory / item)
            else:
                shutil.copy2(str(project_path / item), directory)
        # generate the final build
        os.chdir(directory)
        subprocess.call(["yarn", "generate"])
        # copy the final build directory to the present directory
        shutil.move(src_build_dir, dest_build_dir)
    elif project_type == "rust":
        subprocess.check_call(
            ["cargo", "build", "--release", "--target-dir", directory.resolve()]
        )
        # we create the output folder if it does not exist
        if not os.path.isdir(Path() / "dist"):
            os.mkdir(Path() / "dist")
        # we copy the final file to the current directory inside an out folder
        executable_name = os.getcwd().split(os.path.sep)[-1]
        original_executable_path = (
            STORAGE_DIRECTORY
            / get_cache_directory_name(project_path)
            / "release"
            / executable_name
        )
        shutil.move(
            str(original_executable_path.resolve()),
            project_path / "out" / executable_name,
        )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(prog="setup-project", description=DESCRIPTION)
    parser.add_argument(
        "-g",
        "--generate",
        dest="generate",
        action="store_true",
        help="(default) generate the project dependencies, not applicable in rust projects",  # noqa : E501
    )
    parser.add_argument(
        "directory",
        nargs="?",
        default=os.getcwd(),
        help="the path to the project directory, default: current directory",
    )
    parser.add_argument(
        "-b",
        "--build",
        dest="build",
        action="store_true",
        help="build the project, not applicable in python projects",
    )
    args = parser.parse_args()
    generate, build, directory = args.generate, args.build, Path(args.directory)
    project_type = guess_project_type(directory)
    if not project_type:
        print("Could not guess the project type")
        exit(1)
    if project_type == "rust" or build and not generate:
        build_project(directory, project_type)
    else:
        generate_project(directory, project_type)
