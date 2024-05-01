def call(String gitUrl, String branch){

    environment {
            GIT_CREDENTIALS = credentials("${credentialsId}")
        }
    git branch: "${branch}" url: "${gitUrl}"

}