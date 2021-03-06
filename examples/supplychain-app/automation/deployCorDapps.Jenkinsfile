// Pipeline to build the SmartContracts (Cordapps using Gradle build, or chaincode) and then deploy using ansible
// TODO Add Unit test
// TODO Add Sonar Analysis
pipeline {
    agent {
        label 'gradleslave' // use a gradle based agent
    }
    environment {
        //Define common variables
        //Store root directory
        ROOT_DIR="${pwd()}"
        //KUBECONFIG PATH
        KUBECONFIG="${pwd()}/platforms/shared/configuration/kubeconfig.yaml"

    }
    parameters {
        string(defaultValue: 'deploy-infra-aws', description: 'Which job to get Kubeconfig from?', name: 'KUBE_PROJECT')
        string(defaultValue: 'kube_user.yaml', description: 'Which Kubeconfig filename to use?', name: 'KUBE_FILE')
        string(defaultValue: 'dltplatform-release1-corda', description: 'Cluster name?', name: 'CLUSTER_CONTEXT')
    }

    stages {
        stage('Build CorDapps') {
            // Build the cordapps to create jars. We are building two cordapps here
            // a) cordapp-contract-states and b) cordapp-supply-chain
            // The build files are in build/libs for each folder
            steps {
                dir('examples/supplychain-app/corda/cordApps_springBoot/') {
                    sh """
                        echo 'Java version is ...'
                        java -version

                        echo 'Ensuring correct permissions ...'
                        chmod +x ./gradlew

                        echo 'Cleaning up any previous builds (if not using one shot slave) ...'
                        ./gradlew clean
                        ./gradlew cordapp-contract-states:build
                        ./gradlew cordapp-supply-chain:build

                        echo 'Moving the build files to common location'
                        mv cordapp-contracts-states/build/libs/*.jar build/
                        mv cordapp-supply-chain/build/libs/*.jar build/
                    """
                }
                echo 'Stashing files for later use in another slave ...'
                // Stash files so that another slave can use these
                stash name: 'binary', includes: '**/*.jar', excludes: '**/.git,**/.git/**'

            }
        }

        stage('Deploy CorDapps') {
            agent {
                label 'ansible' // use a ansible based agent
            }
            steps {
                //Withcredentials is needed when connecting to AWS EKS
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'terraform_user',
                    accessKeyVariable: 'ACCESS_KEY',
                    secretKeyVariable: 'SECRET_KEY'
                ]]) {
                    // Copy artefacts from another jenkins job. This stores the kubeconfig file that was generated by infra-creation job
                    copyArtifacts filter: 'kubernetes/*', fingerprintArtifacts: true, projectName: "${params.KUBE_PROJECT}", selector: lastSuccessful(), target: 'platforms/shared/configuration'
                    sh """
                        ls -lat platforms/shared/configuration/kubernetes
                        cp platforms/shared/configuration/kubernetes/${params.KUBE_FILE} ${KUBECONFIG}
                    """
                    echo 'Retrieving files from stash ...'
                    // Copy stashed artefacts from other slave
                    unstash 'binary'
                    // Replace the sample corda network.yaml and fill in required parameters
                    dir('examples/supplychain-app/configuration/') {
                        sh """
                            cp samples/network-cordav2.yaml network.yaml
                            sed -i -e 's+cluster_config+${KUBECONFIG}+g' network.yaml
                            sed -i -e 's+cluster_context+${params.CLUSTER_CONTEXT}+g' network.yaml
                            sed -i -e 's+aws_access_key+${ACCESS_KEY}+g' network.yaml
                            sed -i -e 's+aws_secret_key+${SECRET_KEY}+g' network.yaml
                        """
                    }
                    
                    // Run the playbook to upload the jar files into each node and notary in the corda network
                    sh """                        
                        ls -lat examples/supplychain-app/corda/cordApps_springBoot/build/

                        ansible-playbook platforms/r3-corda/configuration/deploy-cordapps.yaml -e "@./examples/supplychain-app/configuration/network.yaml" -e "source_dir='${ROOT_DIR}/examples/supplychain-app/corda/cordApps_springBoot/build/'"
                    """
                }
            }
        }
    }
}
