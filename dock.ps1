# mvn spring-boot:build-image -Dspring-boot.build-image.imageName=discovery-b

function New-ContainerImageDiscoveryB {
    # run the command in a new process
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c mvn spring-boot:build-image -Dspring-boot.build-image.imageName=discovery-b" -WorkingDirectory .\discovery-b\
}

function New-ContainerImageServiceB {
    # run the command in a new process
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c mvn spring-boot:build-image -Dspring-boot.build-image.imageName=service-b" -WorkingDirectory .\service-b\
}

function New-ContainerImageUIB {
    # run the command in a new process
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c mvn spring-boot:build-image -Dspring-boot.build-image.imageName=ui-b" -WorkingDirectory .\ui-b\
}

Build-DiscoveryB
Start-Sleep 10
Build-ServiceB
Start-Sleep 10
Build-UIB
