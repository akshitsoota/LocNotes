# LocNotes - Smarter Travel Logs

![Swift 2.2](https://img.shields.io/badge/swift-2.2-brightgreen.svg)
![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)

This is my **first** iOS Application. As a part of my internship, I was given a MacBook and I decided to learn Swift, XCode and put together my very own iOS application.
Knowing Android development, I wanted to try the other side!

A special shoutout to all the members of StackOverflow for helping me with bits of code. I have tried to cite as many sources as possible throughout
my project.

### Introduction
Have you ever visited a place and wanted to log it somewhere? This iPhone application allows you to keep track of the locations you've visited by
allowing you to create **location logs**. You give your trip a title, a description (could include what you liked, specific places you visited, people
you met, places you'd like to visit next time you go there, places you didn't like, places you would recommend to a friend, important cultural points
to keep in mind for future trips etc), pictures from that trip and a list of locations you visited on a map. All this together, forms one location log!

Never forget the places you visited, people you met or misplace the pictures you had taken from your trip ever again!

### What is the backend infrastructure?

Thanks to this project, I got to try out Amazon Web Services for the first time! I used Amazon Elastic Cloud Compute (better known as Amazon EC2) to create a web server
which would receive all the backend requests sent by the application including user login, user registration, login token renewal, login token invalidation,
fetching all the location logs, fetching a certain location log, deleting a certain location log and deleting all of the users' location logs.

The web server running on Amazon EC2 was completely written from scratch in Python. I did **not** use any Web Frameworks to support my Python web server.
I have made my Python script running on the web server public and can be accessed [here](https://github.com/akshitsoota/LocNotes-EC2Backend).

All information is stored in a MySQL database on an Amazon Relational Database Service (Amazon RDS) instance. After finishing development and 
taking a look at the tables, I did realize that the way I am storing the information is not the best. In my opinion, a NoSQL Database like
MongoDB would have served better to store the kind of semi-structured data I am storing and retrieving.

All the images that a user uploads is uploaded to Amazon Simple Storage Service (Amazon S3). 
This was possible by integrating Amazon's iOS SDK into my project through CocoaPods.

### Application Flow

![Screenshots Set 1](/app-screenshots/app-screenshot-set1.png?raw=true)

Explaining screens from left to right:

1. Landing page when a user just installs the application
2. Sign up screen
3. Login screen

![Screenshots Set 2](/app-screenshots/app-screenshot-set2.png?raw=true)

Explaining screens from left to right:

1. Screen that lists all of the users' location logs. In this case the user has no location logs
2. Add a new location log screen
3. Screen when you scroll down further and add a few images

![Screenshots Set 3](/app-screenshots/app-screenshot-set3.png?raw=true)

Explaining screens from left to right:

1. MapView and a Search Bar for the user to search for locations they visited and add to their location log
2. Red pins on the MapView indicating non-confirmed locations
3. Settings screen

![Screenshots Set 4](/app-screenshots/app-screenshot-set4.png?raw=true)

Explaining screens from left to right:

1. LocNotes splash screen when the user has enabled Touch ID integration. User can either enter their backup password or use TouchID to unlock the application
2. Viewing a location log
3. Force Touch on a log picture from a location log

![Screenshots Set 5](/app-screenshots/app-screenshot-set5.png?raw=true)

Explaining screens from left to right:

1. Viewing the location of where the picture was taken
2. Force Touch on a location the user visited from a location log
3. Viewing the location of a location that the user visited

### Before running this application...

Before you are able to run this application, you must change two files: `/LocNotes/endpoints_template.plist` and `LocNotes/amazon-aws-credentials_template.plist`.

The file `/LocNotes/endpoints_template.plist` must be renamed to `/LocNotes/endpoints.plist` and `LocNotes/amazon-aws-credentials_template.plist` must be renamed to `LocNotes/amazon-aws-credentials.plist` for them to be picked up by the XCode environment.

Necessary changes must be made to both these files by filling in valid values for all the dummy key-value pairs. These two files are crucial to the LocNotes application connecting to the backend server (instructions to configure that can be found [here](https://github.com/akshitsoota/LocNotes-EC2Backend)) and uploading images correctly.

### What's next?

With the limited time I had over the summer, I wanted to hack together a few of my ideas. This left me with limited time to finish this project in its
entirety. Here is a list of features that I think could be added to this application:

- [ ] Adding the feature to restrict Location Log uploads to Wi-Fi only. The option exists in the Settings but is disabled because I have not coded it
- [ ] Adding a similar option for downloading Location Logs when the user hits refresh
- [ ] Adding an option which allows the application to download non-image based Location Logs on any kind of network but restrict image based Location Logs to be downloaded on Wi-Fi
- [ ] Adding an option to allow users to edit their Location Logs
- [ ] Fix Login Token Issue. Explained further [here](https://github.com/akshitsoota/LocNotes-EC2Backend/blob/master/README.md#logintokenissue)
- [ ] Adding Force Touch on a Location Log on the View Controller that lists all the Location Logs
- [ ] Fix Force Touch warnings that appear in the logger when a Location Log Image/Location Visited is force touched
- [ ] Adding an option allowing the user to search through their Location Logs based on the title or locations visited
- [ ] Fix database string encoding where emojis are not saved correctly
- [ ] Fix ScrollView glitches when adding a new location log. I suspect this happens because of the code I have added to move the text fields up as the keyboard appears. Yet to find a workaround for this issue!
