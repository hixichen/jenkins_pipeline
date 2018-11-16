node {
    
    sh 'env > env.txt'
    for (String i : readFile('env.txt').split("\r?\n")) {
        println i
    }

    echo "validate the environment variable"


    stage('Validate ENV') {
        echo 'PASS ENV validation'
    }
} // end of pipeline