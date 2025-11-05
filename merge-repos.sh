SOURCE_REPO=$1
TARGET_REPO=$2
BRANCH=main
CURRENT_DIR=$(pwd)

if [[ -z "$SOURCE_REPO" ]]; then 
    echo "Missing source repo url"
    exit
fi

if [[ -z "$TARGET_REPO" ]]; then 
    echo "Missing target repo url"
    exit
fi

git clone $SOURCE_REPO source_repo
git clone $TARGET_REPO target_repo

cd source_repo 

git filter-repo --to-subdirectory-filter source_repo 

cd $CURRENT_DIR

cd target_repo 

git remote add -f source_repo ../source_repo
git merge --allow-unrelated-histories source_repo/main
git remote remove source_repo 

cd $CURRENT_DIR

