#!/usr/bin/env bash
. src/misc.sh

run_parameters=$1
current_dir=$PWD

mkdir tmp

if [[ ! -d $lib_dir ]]; then
    mkdir -p $lib_dir 
fi

echo "Installing Galaxy"
echo "================="
# Getting the latest revision with wget from GitHub is faster than cloning it

cd $lib_dir/
if [[ ! -d $local_galaxy_dir ]]; then
    install_galaxy $local_galaxy_dir
fi
cd $current_dir
echo ""

echo "Prepare galaxy tools playbook"
echo "============================="
if [[ ! -d $tool_playbook_dir ]]; then
    mkdir $tool_playbook_dir
fi
if [[ ! -d $tool_playbook_dir/roles ]]; then
    mkdir $tool_playbook_dir/roles
fi
if [[ ! -d $tool_playbook_dir/files ]]; then
    mkdir $tool_playbook_dir/files
fi

mkdir -p $tool_playbook_dir/roles
pushd $tool_playbook_dir/roles
wget https://github.com/galaxyproject/ansible-galaxy-tools/archive/v0.2.1.tar.gz
tar zxvf v0.2.1.tar.gz
mv ansible-galaxy-tools-0.2.1 ansible-galaxy-tools
rm v0.2.1.tar.gz
popd

cp $chosen_tool_dir/*.yaml $tool_playbook_dir/roles/ansible-galaxy-tools/files/ # not sure if useful
cp $chosen_tool_dir/*.yaml $tool_playbook_dir/files/

echo ""
echo "Configure Galaxy"
echo "================"
# Configuration files
cp $galaxy_conf_file_dir/* $galaxy_dir/config/

generate_galaxy_ini $galaxy_dir/config/galaxy.ini

# Tool data
wget https://raw.githubusercontent.com/bgruening/galaxytools/8b913a72a9f6ef1553859cc29a97943095010a2d/tools/rna_tools/sortmerna/tool-data/rRNA_databases.loc.sample 
uncomment_last_lines rRNA_databases.loc.sample $galaxy_dir/tool-data/rRNA_databases.loc 8
mv rRNA_databases.loc.sample $galaxy_dir/tool-data

wget https://raw.githubusercontent.com/ASaiM/galaxytools/88ce150a6e2b37bbd4babe08b5b2bf0faed0a0e8/tools/metaphlan2/tool-data/metaphlan2_db.loc.sample
uncomment_last_lines metaphlan2_db.loc.sample $galaxy_dir/tool-data/metaphlan2_db.loc 1
mv metaphlan2_db.loc.sample $galaxy_dir/tool-data

wget https://raw.githubusercontent.com/peterjc/galaxy_blast/49f5fe70fdb24b284dcfc90cfcddc84942aca9ab/tool-data/blastdb_d.loc.sample
mv blastdb_d.loc.sample $galaxy_dir/tool-data
wget https://raw.githubusercontent.com/peterjc/galaxy_blast/49f5fe70fdb24b284dcfc90cfcddc84942aca9ab/tool-data/blastdb_p.loc.sample
mv blastdb_p.loc.sample $galaxy_dir/tool-data
wget https://raw.githubusercontent.com/peterjc/galaxy_blast/49f5fe70fdb24b284dcfc90cfcddc84942aca9ab/tool-data/blastdb.loc.sample
mv blastdb.loc.sample $galaxy_dir/tool-data

# Dependencies
if [ ! -d $galaxy_dir/dependency_dir ]; then
    mkdir $galaxy_dir/dependency_dir
fi

# FTP
if [ ! -d $galaxy_dir/database/ftp ]; then
    mkdir $galaxy_dir/database/ftp
fi

# Web interface
cp $data_dir/static/welcome.html $galaxy_dir/static/
cp $data_dir/static/welcome.html $galaxy_dir/static/welcome.html.sample
for i in $( ls $data_dir/images/ )
do
    cp $data_dir/images/$i $galaxy_dir/static/images/$i 
done

rm -rf tmp
echo ""

echo "Move to Galaxy repository"
echo "========================="
cd $galaxy_dir
echo ""

launch_virtual_env
pip install -r $current_dir/requirements.txt

echo "Launch Galaxy"
echo "============="
sh run.sh $run_parameters

cd $current_dir
echo ""


