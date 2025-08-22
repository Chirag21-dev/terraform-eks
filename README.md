# terraform-eks
It is a project for deploying the eks cluster through terraform by a jenkins pipeline build using an terraform modules.

At first created the jenkins server using terraform modules which is present in Jenkins_server folder with all the necessary packages such as java,Jenkins,terraform, kubectl, Which is present in screenshot 243.
Next is created a pipeline job and in that pipeline job we called the terraform modules containing the eks cluster module files,with VPC ,subnets and executed the terraform commnands in order to create the EKS cluster in ap-south-1 region which is shown in the screenshot 249.
