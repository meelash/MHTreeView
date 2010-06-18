/*
 * MHTreeView.j
 * AppKit
 *
 * Created by Saleem Abdul Hamid.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@import <AppKit/CPOutlineView.j>


var MHTreeViewDataSource_outlineView_shouldDeferDisplayingChildrenOfItem_                        = 1 << 2;

@implementation MHTreeView : CPOutlineView
{
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        [self setDisclosureControlPrototype:[[MHTreeViewDisclosureButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 10.0, 10.0)]];
    }

    return self;
}

- (void)reloadItem:(id)anItem reloadChildren:(BOOL)shouldReloadChildren
{
    if (!!shouldReloadChildren || !anItem)
        _loadItemInfoForTreeViewItem(self, anItem);
    else
        _reloadItem(self, anItem);

    objj_msgSendSuper({receiver:self, super_class:objj_getClass("CPTableView")}, "reloadData");
}

@end

// FIX ME: We're using with() here because Safari fails if we use anOutlineView._itemInfosForItems or whatever...
var _loadItemInfoForTreeViewItem = function(/*MHTreeView*/ anOutlineView, /*id*/ anItem,  /*BOOL*/ isIntermediate)
{debugger;
    with(anOutlineView)
    {
        var itemInfosForItems = _itemInfosForItems,
            dataSource = _outlineViewDataSource;

        if (!anItem)
            var itemInfo = _rootItemInfo;

        else
        {
            // Get the existing info if it exists.
            var itemUID = [anItem UID],
                itemInfo = itemInfosForItems[itemUID];

            // If we're not in the tree, then just bail.
            if (!itemInfo)
                return [];

            itemInfo.isExpandable = [dataSource outlineView:anOutlineView isItemExpandable:anItem];

            // If we were previously expanded, but now no longer expandable, "de-expand".
            // NOTE: we are *not* collapsing, thus no notification is posted.
            if (!itemInfo.isExpandable && itemInfo.isExpanded)
            {
                itemInfo.isExpanded = NO;
                itemInfo.children = [];
            }
        }

        // The root item does not count as a descendant.
        var weight = itemInfo.weight,
            descendants = anItem ? [anItem] : [];

        if (itemInfo.isExpanded && (!(_implementedOutlineViewDataSourceMethods & MHTreeViewDataSource_outlineView_shouldDeferDisplayingChildrenOfItem_) ||
            ![dataSource outlineView:anOutlineView shouldDeferDisplayingChildrenOfItem:anItem]))
        {
            var index = 0,
                count = [dataSource outlineView:anOutlineView numberOfChildrenOfItem:anItem],
                level = itemInfo.level + 1;

            itemInfo.children = [];

            for (; index < count; ++index)
            {
                var childItem = [dataSource outlineView:anOutlineView child:index ofItem:anItem],
                    childItemInfo = itemInfosForItems[[childItem UID]];

                if (!childItemInfo)
                {
                    childItemInfo = { isExpanded:NO, isExpandable:NO, children:[], weight:1 };
                    itemInfosForItems[[childItem UID]] = childItemInfo;
                }

                itemInfo.children[index] = childItem;

                var childDescendants = _loadItemInfoForTreeViewItem(anOutlineView, childItem, YES);

                childItemInfo.parent = anItem;
                childItemInfo.level = level;
                descendants = childDescendants.concat(descendants);
            }
        }

        itemInfo.weight = descendants.length;

        if (!isIntermediate)
        {
            // row = -1 is the root item, so just go to row 0 since it is ignored.
            var index = MAX(itemInfo.row-weight+1, 0),
                itemsForRows = _itemsForRows;

            descendants.unshift(index, weight);

            itemsForRows.splice.apply(itemsForRows, descendants);

            var count = itemsForRows.length;

            for (; index < count; ++index)
                itemInfosForItems[[itemsForRows[index] UID]].row = index;

            var deltaWeight = itemInfo.weight - weight;

            if (deltaWeight !== 0)
            {
                var parent = itemInfo.parent;

                while (parent)
                {
                    var parentItemInfo = itemInfosForItems[[parent UID]];

                    parentItemInfo.weight += deltaWeight;
                    parent = parentItemInfo.parent;
                }

                if (anItem)
                    _rootItemInfo.weight += deltaWeight;
            }
        }
    }//end of with
    return descendants;
}


@implementation MHTreeViewDisclosureButton : CPDisclosureButton
{
    float _angle;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
        [self setBordered:NO];

    return self;
}

- (void)setState:(CPState)aState
{
    [super setState:aState];

    if ([self state] === CPOnState)
        _angle = PI;

    else
        _angle = -PI_2;
}

@end
