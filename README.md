# Full guided installation for kubeflow into TKG cluster

## CAUTION DO NOT EXECUTE THE SCRIPTS
***IT IS NOT FULLY AUTOMATED, I'M JUST A BEGINNER
IN BASH SCRIPTING!***
Open the scripts, copy line parts by line parts 
and paste them into your console

In the scripts I'll tell you what parts you can
execute together.

You need to manually change some information, based on
your environment.
All additional information regarding configuration are found
in the corresponding multi series blogposts
on https://cloudadvisors.net
___

necessary steps:

1. create tkg cluster
2. patch api-server flags
3. download and patch kubeflow installation files
4. install kubeflow
5. post kubeflow install patches
6. open up http access to kubeflow from outside
7. configure LDAP connector for AD access
8. **you need to do this** >>> make storage class available with Read Write Many volumes
9. install vSphere extension
10. install kubeflow extension

steps 1-7 are in kubeflow-installation
steps 9 and 10 are in addon-installation
 