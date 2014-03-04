## Knife Essentials

# MERGED TO CORE CHEF!

knife-essentials has been merged to Core [Chef](https://github.com/opscode/chef) as of Chef 11 and active development is going on there (though bugfixes are still accepted here, they will need to get into chef too).

# DESCRIPTION:

knife-essentials provides a number of useful knife commands that allow you
to manipulate Chef using a common set of verbs that work on *everything*
that is stored in the Chef server.

    knife diff cookbooks/*apache*
    knife download roles data_bags cookbooks/emacs
    knife upload apache*
    knife list data_bags/users
    knife deps roles/base.json
    cd cookbooks && knife show *base*

More verbs will be added as time goes by.

# INSTALLATION:

This plugin can be installed as a Ruby Gem.

    gem install knife-essentials

You can also copy the source repository and install it using `rake install`.

# PRINCIPLES

* Unified commands that work on everything

knife-essentials thinks verbs come first.  There are only a few things you need to do with
pretty much everything in the system: you upload them, download them, look at
them, edit them, list them, diff them, and delete then.

knife-essentials provides a number of verb commands: `knife diff roles` and `knife list roles`
among them.  These commands work on all types of objects, as well.  You can type
`knife diff roles`, or `knife diff data_bags/users/jkeiser.json`.

* Treat the Chef server is like your filesystem

knife-essentials treats the Chef server like a mirror of a Chef repository.  Most of the
stuff you do with the Chef Server is based on your local repository--a set of files
in directories like `roles`, `data_bags`, `cookbooks`, etc.  The Chef Server has
objects that match them--in fact, you can upload and download the files on your
filesystem to change the file server.

This makes learning the knife commands easy, and makes important commands like
diff, upload and download extremely simple to do and easy to understand.

* Take context into account

  When you're in the `roles` directory, the system knows that's what you are
  working with.  Just type `knife show base.json` and it will show you the base
  role from the server.  knife-essentials knows.

# KNIFE PLUGINS

chef_fs installs a number of useful knife verbs, including:

    knife diff [pattern1 pattern2 ...]
    knife download [pattern1 pattern2 ...]
    knife list [pattern1 pattern2 ...]
    knife show [pattern2 pattern2 ...]

These commands will list data on the server, exactly mirroring
the data in a local Chef repository. So if you type `knife diff data_bags/*s`,
it will diff all data bags that end with `s`.

The commands are also context-sensitive. If you are in the ``roles`` directory
and type `knife show *base*`, you will get the current Chef server contents of all
roles that contain the word `base` in them.

The Knife commands generally run off file patterns (globs you can type on the
command line).  Patterns can include *, ?, ** and character matchers like
[a-z045].

## Prerequisites

To run the knife plugin functionality, install a version of Chef > 0.10.10:

    gem install chef

## knife diff

    knife diff [pattern1 pattern2 ...]

Diffs objects on the server against files in the local repository.  Output is similar to
`git diff`.

## knife download

    knife download [pattern1 pattern2 ...]

Downloads objects from the server to your local repository.  Pass --purge to delete local
files and directories which do not exist on the server.

## knife list

    knife list [pattern1 pattern2 ...]

Works just like 'ls', except it lists files on the server.

## knife show

    knife show [pattern1 pattern2 ...]

Works just like `knife node show`, `knife role show`, etc. except there is One Verb To Rule
Them All.

## knife deps

    knife deps [pattern1 pattern2 ...]

Given a set of nodes, roles, or cookbooks, will traverse dependencies and show
other roles, cookbooks, and environments that need to be loaded for them to
work.  Use `--tree` parameter to show this in a tree structure.  Use `--remote`
to perform this operation against the data on the server rather than the local
Chef repository.

# CONFIGURATION

There are several variables you can set in your `knife.rb` file to alter the
behavior of knife-essentials

## chef_repo_path

    chef_repo_path PATH|[PATH1, PATH2, ...]

This is the path to the top of your chef repository.  Multiple paths are
supported.  If you do not specify this, it defaults to `cookbook_path/..` (for
historical reasons, many knife.rb files contain `cookbook_path`.)

If you specify this or `cookbook_path`, it is not necessary to specify the other paths (`client_path`,
`data_bag_path`, etc.).  They will be assumed to be under the chef_repo_path(s).

## *_path

    client_path PATH|[PATH1, PATH2, ...]
    cookbook_path PATH|[PATH1, PATH2, ...]
    data_bag_path PATH|[PATH1, PATH2, ...]
    environment_path PATH|[PATH1, PATH2, ...]
    node_path PATH|[PATH1, PATH2, ...]
    role_path PATH|[PATH1, PATH2, ...]
    user_path PATH|[PATH1, PATH2, ...]

The local path where client json files, cookbook directories, etc. are stored.
Each supports multiple paths, in which case all files/subdirectories from each
path are merged into one virtual path (i.e. when you `knife list cookbooks` it
will show you a list including all cookbooks from all cookbook_paths).

You generally do NOT need to specify these.  If you do not specify an _path
variable, it is set to chef_repo_path/clients|cookbooks|data_bags|environments|nodes|roles|users.
Each of these supports multiple paths.  If multiple paths are supported, and a
new object is downloaded (say, a new cookbook), the object is downloaded into
the *first* path in the list.  Updated objects stay where they are.

## versioned_cookbooks

    versioned_cookbooks true

This option, when set to `true`, will cause knife-essentials to work with
multiple versions of cookbooks.  In this case, your /cookbooks directory will
have cookbook directory names of the form: `apache2-1.0.0`, `apache2-1.0.1`,
`mysql-1.1.2`, etc.  A full download of /cookbooks will download all versions,
And a diff of a specific version will diff exactly that version and no other.

This is super handy, especially combined with repo_mode "everything," as it will
allow you to back up or restore a full copy of your Chef server.

## repo_mode

    repo_mode "everything"

By default, knife-essentials only maps "cookbooks," "data_bags," environments," and "roles."  If you specify repo_mode "everything", it will map *everything* on the server,
including users, clients and nodes.

The author is not particularly happy about the necessity for this, and will try
to get rid of it as soon as a way is found to avoid violating the Principle of
Least Surprise.  The reason things are split this way is that most people don't
store users, clients and nodes in source control.  `knife deps` fares very
poorly due to the way things are; but `knife diff` gets surprising if it shows
nodes, which aren't usually in your repo.

## NOTE ABOUT WILDCARDS

knife-essentials supports wildcards internally, and will use them to sift through objects
on the server.  This can be very useful.  However, since it uses the same wildcard
characters as the Unix command line (`*`, `?`, etc.), you need to backslash them so that
the `*` actually reaches the server.  If you don't, the shell will expand the * into
actual filenames and knife will never know you typed `*` in the first place.  For example,
if the Chef server has data bags `aardvarks`, `anagrams` and `arp_tables`, but your local
filesystem only has `aardvarks` and `anagrams`, backslashing vs. not backslashing will
yield slightly different results:

    # This actually asks the server for everything starting with a
    $ knife list data_bags/a\*
    aardvarks/ anagrams/ arp_tables/
    # But this ...
    $ knife list data_bags/a*
    aardvarks/ anagrams/
    # Is actually expanded by the command line to this:
    $ knife list data_bags/aardvarks data_bags/aardvarks
    aardvarks/ anagrams/

You can avoid this problem permanently in zsh with this alias:

    alias knife="noglob knife"
