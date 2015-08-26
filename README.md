
###The Basics
Preference Spy is an extension for [Komodo IDE](http://komodoide.com/) and [Komodo Edit](http://komodoide.com/komodo-edit/).
It simplifies inspecting user preferences.

###Installation
The extension XPI is available at https://github.com/ervumlens/ko-preferencespy/releases .

Once installed, the extension adds a new "Preference Spy" menu under the main "Tools" menu,
and a "All (Read-Only)" page in the Preferences dialog.

###Usage

Preference Spy has two main functions: viewing all preferences and monitoring preference changes.

To view all preferences, simply open a Preferences dialog, enable the "Show Advanced" option,
and click on the "All (Read-Only)".

To monitor preference changes, open the "Preference Spy" menu under "Tools",
and choose a "Log (whatever) Pref Changes" option. Now preference changes will be logged to Komodo's
standard error log.

###Limitations

* Temporary or transient preference changes are not logged.
These are changes that look fine in the preference dialog but do not appear to be applied as expected.

* Certain project preferences are not logged. This is being investigated.

* The search panel in the Preferences dialog does not search for nested preference values.

###Build

Building Preference Spy requires the [CoffeeScript](http://coffeescript.org) compiler available on the environment `PATH` and an installation of Komodo Edit or IDE.
The [`ko-preferencespy`](https://github.com/ervumlens/ko-preferencespy) repository includes Komodo macros that build the extension.
Just clone the repo, open a new Komodo project from within the `ko-preferencespy` directory, and run the macros from the Komodo toolbox.

###Questions? Problems? Suggestions?

Report bugs, make enhancement requests, or ask questions at https://github.com/ervumlens/ko-preferencespy/issues . Just click on the big "New Issue" button.

###Thank Yous

Thanks to Komodo Edit's developers and contributors, past and present, for making an editor that's enjoyable to use.

Thanks to Jeremy Ashkenas for creating CoffeeScript.
