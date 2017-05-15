param([String]$key,[String]$version)

function setProjectVersion([String]$project, [String]$version) {
	$fileName =  resolve-path  ".\src\$project\$project.csproj"
    $content = [xml](Get-Content $fileName)
	$v = $content.CreateElement("Version")
	$v.set_InnerXML($version)
    $content.Project.PropertyGroup.AppendChild($v)
    $content.Save($fileName)
}

function publishProject([String]$project,[String]$version) {
	cd ".\src\$project"
	& dotnet pack -c Release
	if ($LastExitCode -ne 0) {
		throw "Error ($LastExitCode) during dotnet pack"
	}
	$file = Get-Item "bin\Release\*.$version.nupkg"
	nuget push $file.FullName $key -Source https://api.nuget.org/v3/index.json
	if ($LastExitCode -ne 0) {
		throw "Error ($LastExitCode) during nuget push"
	}
	cd ..\..
}

if ($version -ne "") {
	$projectDirectories = Get-ChildItem .\src -Recurse -Filter "*.csproj" | % { $_.Directory.Name } 

	ForEach ($directory in $projectDirectories) {
		setProjectVersion $directory $version
	}
	
	& dotnet restore
	if ($LastExitCode -ne 0) {
		throw "Error ($LastExitCode) during dotnet restore"
	}

	ForEach ($directory in $projectDirectories) {
		publishProject $directory $version
	}
}
