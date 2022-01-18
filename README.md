# CodeLauncher

As a web developer, you need to run many different processes for your development work. CodeLauncher provides a hub for all the server software you need, and you can organize them by project and check their output accordingly.

## Core Features

- Manage processes by project
- Check the output of each process
- Auto start projects when CodeLauncher starts
- Manage environment variables of each process
- Export/import projects for sharing between team members

## Open Source

If you have used supervisor on Linux before, you will find the concept is quite similar. CodeLauncher works like a GUI version of supervisor for macOS. You can also grab the source code and build it yourself if you want.

## DEVELOPMENT_TEAM Setting

To use your DEVELOPMENT_TEAM for building the app, please follow these steps:

Create a `local.xcconfig` file at the root level of the project. This file is already ignored in gitignore.

Put your DEVELOPMENT_TEAM setting in `local.xcconfig` like this:

```
DEVELOPEMENT_TEAM = 12345ABCDE
```

You do not need to create this file from Xcode, it can be created with a simple command like this:

```
echo "DEVELOPMENT_TEAM = 12345ABCDE" > local.xcconfig
```
