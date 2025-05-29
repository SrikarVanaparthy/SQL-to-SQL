// pipeline {
//     agent any

//     parameters {
//         string(name: 'SourceSQLHost', defaultValue: '10.128.0.29', description: 'Source SQL Server Host IP')
//         string(name: 'TargetSQLHost1', defaultValue: '10.128.0.28', description: 'Target SQL Server 1 Host IP')
//         // string(name: 'TargetSQLHost2', defaultValue: '192.168.1.30', description: 'Target SQL Server 2 Host IP')
//         string(name: 'SqlUsername', defaultValue: 'sa', description: 'SQL Server Username')
//         password(name: 'SqlPassword', defaultValue: 'Password@123', description: 'SQL Server Password')
//         string(name: 'InstanceName1', defaultValue: '34.71.151.139,1433', description: 'Source instance name')
//         string(name: 'InstanceName2', defaultValue: '34.9.117.49,1433', description: 'Target 1 instance name')
//         // string(name: 'InstanceName3', defaultValue: '34.11.117.99,1433', description: 'Target 2 instance name')
//     }

//     stages {
//         stage('Checkout Repository') {
//             steps {
//                 git branch: 'main', url: 'https://github.com/SrikarVanaparthy/SQL-to-SQL.git'
//             }
//         }

//         stage('Migrate Users in Parallel') {
//             parallel {
//                 stage('Migrate to Target 1') {
//                     steps {
//                         pwsh """
//                             ./SqlUserMigration.ps1 `
//                                 -SourceSQLHost '${params.SourceSQLHost}' `
//                                 -TargetSQLHost1 '${params.TargetSQLHost1}' `
//                                 -SqlUsername '${params.SqlUsername}' `
//                                 -SqlPassword '${params.SqlPassword}' `
//                                 -InstanceName1 '${params.InstanceName1}' `
//                                 -InstanceName2 '${params.InstanceName2}'
//                         """
//                     }
//                 }

//                 // stage('Migrate to Target 2') {
//                 //     steps {
//                 //         pwsh """
//                 //             ./SqlUserMigration.ps1 `
//                 //                 -SourceSQLHost '${params.SourceSQLHost}' `
//                 //                 -TargetSQLHost1 '${params.TargetSQLHost2}' `
//                 //                 -SqlUsername '${params.SqlUsername}' `
//                 //                 -SqlPassword '${params.SqlPassword}' `
//                 //                 -InstanceName1 '${params.InstanceName1}' `
//                 //                 -InstanceName2 '${params.InstanceName3}'
//                 //         """
//                 //     }
//                 // }
//             }
//         }
//     }
// }


pipeline {
    agent any

    parameters {
        string(name: 'SourceSQLHost', defaultValue: '10.128.0.29', description: 'Source SQL Server Host IP')
        string(name: 'TargetSQLHost1', defaultValue: '10.128.0.28', description: 'Target SQL Server 1 Host IP')
        string(name: 'SqlUsername', defaultValue: 'sa', description: 'SQL Server Username')
        password(name: 'SqlPassword', defaultValue: 'Password@123', description: 'SQL Server Password')
        string(name: 'InstanceName1', defaultValue: '34.71.151.139,1433', description: 'Source instance name')
        string(name: 'InstanceName2', defaultValue: '34.9.117.49,1433', description: 'Target 1 instance name')
    }

    stages {

        stage('Checkout Repository') {
            steps {
                git branch: 'main', url: 'https://github.com/SrikarVanaparthy/SQL-to-SQL.git'
            }
        }

        stage('Install sqlcmd') {
            steps {
                sh '''
                    curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
                    curl https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list
                    sudo apt-get update
                    sudo ACCEPT_EULA=Y apt-get install -y mssql-tools unixodbc-dev

                    echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
                    echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile
                    export PATH="$PATH:/opt/mssql-tools/bin"
                '''
            }
        }

        stage('Migrate Users in Parallel') {
            parallel {
                stage('Migrate to Target 1') {
                    steps {
                        pwsh """
                            ./SqlUserMigration.ps1 `
                                -SourceSQLHost '${params.SourceSQLHost}' `
                                -TargetSQLHost1 '${params.TargetSQLHost1}' `
                                -SqlUsername '${params.SqlUsername}' `
                                -SqlPassword '${params.SqlPassword}' `
                                -InstanceName1 '${params.InstanceName1}' `
                                -InstanceName2 '${params.InstanceName2}'
                        """
                    }
                }
            }
        }
    }
}
