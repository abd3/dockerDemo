FROM node
#Install various helper tools and Salesforce DX CLI
RUN npm install --global sfdx-cli && \
  sfdx force --help
