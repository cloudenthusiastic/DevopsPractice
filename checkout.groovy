def call(String gitUrl, String branch){
    git branch: "${branch}" url: "${gitUrl}"
}
