#import <AppKit/AppKit.h>

enum SSYSidebarControllerWhichEdge_enum {
    SSYSidebarControllerWhichEdgeRight,
    SSYSidebarControllerWhichEdgeLeft,
    SSYSidebarControllerWhichEdgeBottom,
    SSYSidebarControllerWhichEdgeTop
};
typedef enum SSYSidebarControllerWhichEdge_enum SSYSidebarControllerWhichEdge;

/*!
 @brief    SSYSidebarController toggles a *sidebar view* in a window between
 completely collapsed and comletely expanded states, simultaneously adjusting,
 as appropriate, the size and/or position of a sibling adjacent *main* view
 and the window in which both views reside

 @details

 ## Auto Layout
 
 SSYSidebarController does not use Auto Layout.  I have not thought much about
 whether or not you could, for instance, use Auto Layout in the main and
 sidebar views.  The use case I had for writing SSYSidebarController were
 to replace NSDrawer instances in a old pre Auto-Layout project.
 
 ## View Size Variability
 
 Each time the sidebar is expanded, you may specify a minimum length (height
 or width, depending on `whichEdge`) for the main view.  If this is less than
 its current length, SSYSidebarView will partially collapse the main view, down
 to that minimum, before expanding the window.
 
 The sidebar length (height or width, depending on `whichEdge`) is fixed during
 -awakeFromNib.  Attempting to change it may cause unexpected results.  Its
 other dimention (width or height) may be changed.
 
 ## Window Edges

 The "sidebar" view can appear on any of the four window edges; in
 other words it can also be a *topbar* or *bottombar*.  But we call it a
 *sidebar* in all cases.  Think *side information* or *side controls*.  You may
 theoretically put sidebars on all four edges of a window, although I've only
 tested one and two.

 ## Usage

 Note that, unlike NSSplitViewController, SSYSidebarController does not inherit
 from NSViewController.  It actually controls not one view but two – the *main*
 and the *sidebar* views.  Typically, you instantiate one SSYSidebarController
 in a xib or storyboard that contains the window, main view and sidebar view,
 and the latter two should be connected to SSYSidebarController's outlets.
 It is recommended to place the main view and sidebar view as siblings in a
 window's content view, abutting one another and filling the content view in
 the same way as they would when the sidebar is expanded.  Nonetheless, your
 window will initially appear with the sidebar collapsed, because
 SSYSidebarController collapses it during its -awakeFromNib.

 You may also instantiate SSYSidebarController in code.

 ## Relation to NSDrawer and NSSplitView

 Since 2012 or so, NSDrawer has been dis-recommended by Apple.  When
 a window with a NSDrawer loads, a bunch of crap is logged to the Xcode
 console, and also, sometimes, drawer content does not load.  One solution is
 to replace NSDrawer with NSSplitView and NSSplitViewController, but those
 two are quite complicated to use, buggy.  If you have obvious buttons in
 your user interface for opening and closing the drawer, maybe you don't need
 the draggable devider bar.  In that case, you can simply put your drawer
 contents in a sibling subview to the window's main view and instantiate a
 SSYSidebarController in your window controller.

 ## Troubleshooting

 If your views are not sizing as expected, think about their autoresize masks
 ("springs and struts" in Interface Builder), and those of their subviews.
 */
IB_DESIGNABLE
@interface SSYSidebarController : NSObject

@property (assign) IBOutlet NSView* mainView;
@property (assign) IBOutlet NSView* sidebarView;

/*!
 @details  The values of this property must be one of the values of the enum
 SSYSidebarControllerWhichEdge.  Unfortunately, as of Xcode 8.2, Interface
 Builder does not know how to show a control for enum types, and thus will not
 show a control for an enum typed property in the Attributes Inspector.  To
 work around this limitation so that a control shows in Interface Builder, we
 type this property as NSInteger.  Sigh.
 */
@property (assign) IBInspectable NSInteger whichEdge;

/*!
 @brief    Initializes a SSYSidebarController instance and collapses the given
 sidebar view so that only the given main view is visible

 @details  Typically, you instantiate SSYSidebarController in Interface Builder
 and will not use this method.  If instead you instantiate SSYSidebarController
 in code, you will call this method, possibly from your in your window
 controller's -awakeFromNib implementation.

 @param    mainView  The main part of the window, which should be visible when
 the window initially opens
 @param    sidebarView  The auxiliary, aka "sidebar" or "drawer" view, which is
 initially collapsed.
 */
- (instancetype)initWithMainView:(NSView*)mainView
                     sidebarView:(NSView*)sidebarView
                       whichEdge:(SSYSidebarControllerWhichEdge)whichEdge;

/*!
 @brief    Expands or collapses the sidebar view of the receiver

 @details  When expanding, borrows length from the main view as available and,
 if that is not enough, makes the window bigger, and if would cause the window
 to overflow the screen, moves the window enough in the opposite direction to
 prevent that overflow.  When collapsing, restores to the main view whatever
 length was borrowed in the previous expanding.  Does nothing if expandPort
 is passed YES when the sidebar is already expanded, or NO when the sidebar is
 already collapsed.

 @param    expandSidebar  YES to expand the sidebar, NO to collapse
 @param    mainViewMinimum  When expanding, the minimum length (width or
 height) in the direction of the expanding, to which the main view may view
 may be collapsed to accomodate the expansion of the sidebar view.  Ignored
 when collapsing.
 @param    animate  YES to animate the expanding or collapsing
 */
- (void)expandSidebar:(BOOL)expand
      mainViewMinimum:(CGFloat)mainViewMinimum
              animate:(BOOL)animate ;

@end
