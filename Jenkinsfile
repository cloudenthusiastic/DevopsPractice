@Library("shared-library") _

pipeline {
    agent any
    stages{
        stage{
            steps{
                script{
                    checkout("https://github.com/cloudenthusiastic/DevopsPractice.git","main")
                }
            }
        }
    }
}