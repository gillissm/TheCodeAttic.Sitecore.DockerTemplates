# TheCodeAttic.Sitecore.DockerTemplates

# Using dotnet new for Sitecore Docker

As I have been diving into leveraging docker for my Sitecore development, I have been seeking how to reduce the amount of work my team members must take to they themselves getting up and running. (One of the main ideas is the simplification of standing up an environment.)

In my experimenting and learning, I found that one of the most critical things to consistant success was the folder and file structure used especially building custom images. This hurdle became my focus, as I wanted to find the easiest way for others to start building custom images and begin working with Sitecore via docker. Sitecore has done a great job creating the [docker-examples repository](https://github.com/Sitecore/docker-examples) to demonstrate how things could work. (I do not want to discount how much time and effort has gone into creating this set of examples and related documents, as it was my main starting point, too.) As great as it is, I found it a bit overwhelming trying to parse out the bare-minimum as launching point.

## Blueprint to Sitecore Image Building

I my process I determine there is a basic three-step approach to Sitecore and docker.

### Organization or Base Images

The first thing that must be accomplished is the creation of your organization (or base images). Sitecore provides images with the bare install of Sitecore, but any additional modules you may need such as SXA or SPE or DEF, must be layered/copied in from Sitecore provided asset images. Because of docker's layering ability of images, I find it most beneficial to create these organizational images onetime and allow them to be referenced as needed by individuals and teams.

### Project Images

This leads to the idea of a project image. Project images is an opportunity to allow for custom needs of a specific project to layer in on-top of the organizational image. At the start of a project, maybe there is nothing additional that needs done, and you can pass through the organization image with no additions. As a site matures, it may become beneficial to pre-load content or custom code. Therefore, already having established a project specific image set to use, these additions can be built and those consumign the images do not have to change/update any files, just pull the latest tagged image.

### Running the Project

Finally, there is running the project images. This is is a set of folders, scripts, and a docker-compose file that pulls the project images, and maybe some of the organizational images from the registry to be ran.

## TheCodeAttic.Sitecore.DockerTemplates Package

The above blueprint involves a lot of files and folders, which because of the nature of docker are usually managed in a relative path manner to each other. Thus, I find it can be easy to accidentally move a folder around or change the name of something and end-up spending our spinning trying to figure out a cryptic failed run or build error from docker.

To help the community, I have created a dotnet new template that creates the basic file and folder structure required for each of these levels, that can then quickly be modified for your custom needs and be off and developing in a shorter time.

### Getting Started

Dotnet templates can be any combination of files, folders, and scripts with a JSON based manifest file which are packed into a nuget package and installed via the dotnet CLI.

To get TheCodeAttic.Sitecore.DockerTemplates package, open PowerShell and run:

```powershell

dotnet new -i TheCodeAttic.Sitecore.DockerTemplates

```

It is that simple....if you would rather you can visit the nuget page and manually [download the package from https://www.nuget.org/packages/TheCodeAttic.Sitecore.DockerTemplates/](https://www.nuget.org/packages/TheCodeAttic.Sitecore.DockerTemplates/) or even pull the source from GitHub at [https://github.com/gillissm/TheCodeAttic.Sitecore.DockerTemplates](https://github.com/gillissm/TheCodeAttic.Sitecore.DockerTemplates)

Install via the package is done as follows.

```powershell
dotnet new -i <FULL PATH TO THE nupkg YOU DOWNLOADED >
```

You can confirm it is installed by running the following to list all templates, looking for **XP.5.Docker.ProjectTemplates**, **XP.5.Docker.RunTemplate**, and **XP.5.DockerBaseTemplate**

```powershell
dotnet new
```

![docker new list](dockertemplate-1.png)

### Using the Templates

Currently there are three templates that can be created, each targeting either Sitecore 10.0.1 or 10.1.

#### XP.5.Docker.BaseTemplate

This template is meant to support the creation of organization (or base) image creation. It leverages the Sitecore base images and by default installs SPE and SXA, but you can further modify it to support any additional modules your organization may need. The default is to install templates pre-configured for Sitecore 10.1, but via a simple flag you can indicate 10.0.1 or even 9.3 (which at this time is empty).

![help for template](dockertemplate-3.png)

```powershell
dotnet new sc-dockerbase -n NameOfFolderToCreateIn
```

![creation of base templates](dockertemplate-2.png)

#### XP.5.Docker.ProjectTemplate

Following the blueprint, I set forth, this template provides the structure to consuming the organization images and build the appropriate project images for the team. Similar to the organization image template command the default creation is Sitecore 10.1, but you can leverage the same _-sv_ parameter option to select 10.0.1 (10_0) or the empty folder for 9.3 (9_3).

```powershell
dotnet new sc-dockerproject -n NameOfFolderToCreatIn
```

![creation of base templates](dockertemplate-4.png)

#### XP.5.Docker.RunTemplate

Finally, there is the template (maybe the most important of all) to provide the structure that you would use to run the images as an orchestrated set of containers for development, testing, or demoing.

```powershell
dotnet new sc-dockerrun -n NameOfFolderToCreateIn
```

To create a run template which supports Horizon call the new command with the '-E' or '--EnableHorizon' parameter.

```powershell
dotnet new sc-dockerrun -n NameOfFolderToCreateIn -E

dotnet new sc-dockerrun -n NameOfFolderToCreateIn --EnableHorizon
```

![creation of base templates](dockertemplate-5.png)

Two key next steps after creating this template, is to a) update the Project.env so it points to the correct _Organization_ and _Project_ images to be ran, and b) to then execute init.ps1 to convert the 'Project.env' into a proper '.env' for docker-compose. Running the init.ps1 is required only the first time you setup your run structure.

![run the init.ps1](dockertemplate-6.png)

## That's it

That is the bare details required to begin quickly standing up the files and folders required to create you own custom Sitecore docker images, and then to begin running them. I am working on more detailed documentation for each template set, as to key areas that require updating, but this should allow you to get experimenting.

## References

* [https://www.nuget.org/packages/TheCodeAttic.Sitecore.DockerTemplates](https://www.nuget.org/packages/TheCodeAttic.Sitecore.DockerTemplates/)
* [https://github.com/gillissm/TheCodeAttic.Sitecore.DockerTemplates](https://github.com/gillissm/TheCodeAttic.Sitecore.DockerTemplates)
* [https://docs.microsoft.com/en-us/dotnet/core/tools/custom-templates](https://docs.microsoft.com/en-us/dotnet/core/tools/custom-templates)

