MHTreeView

requires:
AppKit/CPOutlineView.j

This is a subclass of CPOutlineView that expands elements towards the top rather than downward. All that I've modified is the code for adding the items to the rows in the table data source, the code for recording the rows in the table source back into the the item, and the direction that the disclosure arrow point when expanded.

As far as I could tell in glancing through the source, it seems all the other features of CPOutlineView are based on the UID of the item and not its row position, so presumably they should all work without modification. If I come across any problems I'll push a fix.

To Use:

Just download MHTreeView to your directory and @import it wherever you want to use it.