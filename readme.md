# Overview

This is the application-specific code necessary to implement the EC2 + CodeDeploy architecture for Docker-based
applications.

# Directory Layout

| Folder Name | Description                                                                             | other notes                                                                                        |
|-------------|-----------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------|
| codedeploy  | Code that's executed inside of the EC2 Virtual Machines to get the application running. | Pulls images, Stops existing containers, starts new containers                                     |
| example-app | This is the application-specific code.                                                  | TBD                                                                                                |
| terraform   | IaC to spin up our application, and two environments; develop and production            | variables and details here will need to be customized as appropriate for a real-world application. |
| Jenkinsfile | Responsible for the Continuous Deployment of the codedeployed application.              | Modify as appropriate; this is a multi-branch pipeline without any kind of approval gates in place |

# What about the infrastructure as code stuff?

Practically speaking, the terraform folder should **NOT reside within the application-specific repository** as this
reduces
the ability to utilize modules across projects. I tend to prefer that the terraform code be inside of a shared "Ops"
type of repository that's managed by the ops team so developers don't need to be concerned about anything related to the
infrastructure.
