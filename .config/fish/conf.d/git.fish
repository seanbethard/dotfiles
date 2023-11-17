#!/usr/bin/var fish

# git functions
function repos --description 'Show git directory structure.'
    tree -L 2 $etc/git
end

function deploy_test --description 'Deploy development environment.'
    git pull
    git push origin development
end

function deploy_staging --description 'Deploy staging.'
    git pull
    git checkout staging
    git pull
    git merge development
    git push origin staging
    git checkout development
end

function deploy_production --description 'Deploy production.'
    git pull
    git checkout production
    git pull
    git merge development
    git push origin production
    git checkout staging
end

function deploy_staging_and_production --description 'Deploy staging and production.'
    git pull
    git checkout staging
    git pull
    git merge development
    git push origin staging
    git checkout production
    git pull
    git merge staging
    git push origin production
    git checkout development
end
