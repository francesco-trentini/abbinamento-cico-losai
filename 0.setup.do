clear all

// Setup
if c(username)=="your_user_name" {
    global localdir "your_local_dir"
}
global dirprogetto "project_dir"
global pwd $localdir$dirprogetto

* work directory
cd ${`pwd'}

* create local directories
mkdir input
mkdir output
mkdir temp

* reference to local directories
global id "${pwd}/input"
global od "${pwd}/output"
global td "${pwd}/temp"
