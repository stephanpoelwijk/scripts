#!/bin/sh
SITE_NAME=$1
CURRENT_DIR=$(pwd)

if [[ -z "$SITE_NAME" ]]; then 
    echo "No site name was given"
    exit 
fi

rm -rf $SITE_NAME 

npm init vite@latest $SITE_NAME --- --template react-ts --rolldown false --interactive false

cd $SITE_NAME 

# Package stuff
npm install lodash
npm install -D @types/lodash @types/leaflet @types/node
npm install tailwindcss @tailwindcss/vite

npm install

# Tailwind config
sed -i "" 's/react()/react(),tailwind()/' vite.config.ts
sed -E -i "" "s/^(import react.*)$/\1\nimport tailwind from '@tailwindcss\/vite';/" vite.config.ts
sed -E -i "" 's/^(:root.*)$/@import "tailwindcss";\n\n\1/' src/index.css

# Shadcn config
jq '. += { "compilerOptions" : { "baseUrl" : ".", "paths" : { "@/*" : ["./src/*"]}} }' tsconfig.json > tsconfig.json.modified

cat tsconfig.app.json | sed 's/\/\*.*\*\///' | jq '.compilerOptions += {"baseUrl":"."}' > tsconfig.app.json.without_comments
jq '.compilerOptions += { "paths": { "@/*" : [ "./src/*" ]}}' tsconfig.app.json.without_comments > tsconfig.app.json.modified

sed -E -i "" "s/^(import react.*)$/import path from 'path';\n\1/" vite.config.ts
sed -E -i "" 's/(.*plugins.*)/\1\nresolve: \{alias: \{ "@": path.resolve(__dirname, ".\/src"), \},\},/' vite.config.ts

# Make the modified files the current ones so Shadcn install does not fail
mv -f tsconfig.json.modified tsconfig.json
mv -f tsconfig.app.json.modified tsconfig.app.json

rm tsconfig.app.json.without_comments

# Finally install shadcn and some components
npx shadcn@latest init  --base-color gray

npx shadcn@latest add button
npx shadcn@latest add card
npx shadcn@latest add input
npx shadcn@latest add select 

cd $CURRENT_DIR

