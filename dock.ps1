# mvn spring-boot:build-image -Dspring-boot.build-image.imageName=discovery-b

function New-ContainerImageDiscoveryB {
    # run the command in a new process
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c mvn spring-boot:build-image -Dspring-boot.build-image.imageName=discovery-fooda" -WorkingDirectory .\discovery-fooda\
}

function New-ContainerImageServiceB {
    # run the command in a new process
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c mvn spring-boot:build-image -Dspring-boot.build-image.imageName=service-fooda" -WorkingDirectory .\service-fooda\
}

function New-ContainerImageUIB {
    # run the command in a new process
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c mvn spring-boot:build-image -Dspring-boot.build-image.imageName=ui-fooda" -WorkingDirectory .\ui-fooda\
}

Build-DiscoveryB
Start-Sleep 10
Build-ServiceB
Start-Sleep 10
Build-UIB
