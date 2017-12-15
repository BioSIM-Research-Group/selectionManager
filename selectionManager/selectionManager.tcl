package provide selV 1.0

#
# SelectionViewer v1.0
#
# GUI to create atom selection in VMD.
#
# (c) 2017 by Nuno M. F. Sousa A. Cerqueira <nscerqueira@gmail.com> or <nscerque@fc.up.pt> and Henrique S. Fernandes <henrique.fernandes@fc.up.pt> or <henriquefer11@gmail.com>
#
###########################################################################################
#
# create package and namespace and default all namespace global variables.

namespace eval selV:: {

    variable version		"1.1"
    variable layers         {} ;# values of the combobox
    variable selection      {}
    variable widget         "tree"
    variable topGui         .selV
    variable optionsGui     .selV.options
    variable entrySel          ""
    variable item           ""
    variable VMDKeywords    {all none backbone sidechain protein nucleic water waters vmd_fast_hydrogen helix alpha_helix helix_3_10 pi_helix sheet betasheet extended_beta bridge_beta turn coil at acidic cyclic acyclic aliphatic alpha amino aromatic basic bonded buried cg charged hetero hydrophobic small medium large neutral polar purine pyrimidine surface lipid lipids ion ions sugar solvent glycan carbon hydrogen nitrogen oxygen sulfur noh heme conformationall conformationA conformationB conformationC conformationD conformationE conformationF drude unparametrized name type backbonetype residuetype index serial atomicnumber element residue resid resname altloc insertion chain segname segif fragment pfrag nfrag numbonds structure pucker user radius mass charge beta occupancy {all within 4 of} {same residue as} and as or to all within}
    variable selectionHistory {}
    variable selectionHistoryID ""
    variable animationOnOff 1
    variable animationDuration 2.0
    
    variable graphicsID ""
    variable pickedAtomsBAD {}
}



#### START GUI

proc selV::startGui {} {
	
	toplevel $selV::topGui
	

	#### Title of the windows
	wm title $selV::topGui "Selection Manager $selV::version " ;# titulo da pagina


    #### Change the location of window
    
    #mainmenu location
    menu main move 0 50

    # screen width and height
    set sWidth  [winfo vrootwidth  $selV::topGui]
    set sHeight [expr [winfo vrootheight $selV::topGui] - 80]

    #window wifth and height
    set wWidth  [winfo reqwidth $selV::topGui]
    set wHeight [winfo reqheight $selV::topGui]

    display reposition 0 [expr ${sHeight} + 10]
    display resize [expr $sWidth - 315] ${sHeight}

    #wm geometry window $VBox::topGui 40x59 0
    wm geometry $selV::topGui 300x${sHeight}+[expr $sWidth - 310]+25

    

    # menu graphics
    menu graphics move $sWidth [expr ${sHeight} - 15]

    #### FRAME 0
    grid [frame $selV::topGui.frame0] -row 0 -column 0 -padx 1 -pady 1 -sticky news
       	grid [ttk::label $selV::topGui.frame0.l1 -text "Molecule ID:"] -in $selV::topGui.frame0 -row 0 -column 0 -sticky nsew 
        grid [ttk::combobox $selV::topGui.frame0.cb1 -values $selV::layers -postcommand selV::PDBList ] -in $selV::topGui.frame0 -row 0 -column 1 -sticky ew

		# label     
		grid [ttk::label $selV::topGui.frame0.lb -text "Selection Tree:"] -in $selV::topGui.frame0 -row 1 -column 0 -sticky news -columnspan 2


	#### FRAME 1 - Paned Window

	grid [ttk::panedwindow $selV::topGui.frame1 -orient vertical] -row 1 -column 0 -padx 2 -pady 1 -sticky news


        # ttk::frame
        $selV::topGui.frame1 add [ttk::frame $selV::topGui.frame1.frame10] -weight 2 

            #frame 1
            grid [ttk::frame $selV::topGui.frame1.frame10.f0] -in $selV::topGui.frame1.frame10 -row 0 -column 0 -sticky news



		    #treeView
		    grid [ttk::treeview $selV::topGui.frame1.frame10.f0.tree -show tree -height 18 -yscroll "$selV::topGui.frame1.frame10.f0.vsb set" ] -in $selV::topGui.frame1.frame10.f0 -row 0 -column 0 -sticky news 
		
		
            grid [ttk::scrollbar $selV::topGui.frame1.frame10.f0.vsb -orient vertical -command "$selV::topGui.frame1.frame10.f0.tree yview"] -in $selV::topGui.frame1.frame10.f0 -row 0 -column 1  -sticky ns 
 

            #frame 2
            grid [ttk::frame $selV::topGui.frame1.frame10.f1] -in $selV::topGui.frame1.frame10 -row 1 -column 0 -sticky we 

                # label     
                grid [ttk::label $selV::topGui.frame1.frame10.f1.lb1 -text "Atom Selection:"] -in $selV::topGui.frame1.frame10.f1 -row 0 -column 0 -columnspan 3

                # entry
                ttk::style layout entry {
                  Plain.Entry.field -sticky nswe -children {
                      Plain.Entry.padding -sticky nswe -children {
                          Plain.Entry.textarea -sticky nswe
                      }
                  }
                }

                variable customSelection ""
                grid [ttk::entry $selV::topGui.frame1.frame10.f1.en1 -style entry -textvariable selV::customSelection -validate all -validatecommand {selV::entrySelection %P 0;selV::autocomplete %W %d %v %P $selV::VMDKeywords}] -in $selV::topGui.frame1.frame10.f1 -row 1 -column 0 -sticky ew  -columnspan 3
            
               

            #button
            grid [ttk::button $selV::topGui.frame1.frame10.f1.bt1 -width 3 -text "Add" -command {selV::addSelection}] -in $selV::topGui.frame1.frame10.f1 -row 2 -column 1
            grid [ttk::button $selV::topGui.frame1.frame10.f1.bt2 -width 5 -text "Apply" -command {selV::updateSelection} -state disabled] -in $selV::topGui.frame1.frame10.f1 -row 2 -column 2 

            grid columnconfigure $selV::topGui.frame1.frame10.f1                      0 -weight 8


        # frame
        $selV::topGui.frame1 add [ttk::frame $selV::topGui.frame1.frame11] 
            
            # Label
            grid [ttk::label $selV::topGui.frame1.frame11.l1 -text "Representations"] -in $selV::topGui.frame1.frame11 -row 0 -column 0 

		    #LISTBox
		    grid [tablelist::tablelist $selV::topGui.frame1.frame11.lb1 \
			    -showeditcursor true \
			    -columns {0 "#" center 0 "" center 0 "Atom Selections" center} \
			    -stretch 2 \
			    -background white \
			    -yscrollcommand [list $selV::topGui.frame1.frame11.vsb set] \
			    -xscrollcommand [list $selV::topGui.frame1.frame11.hsb set] \
                -editendcommand selV::showOrHideRep \
			    -height 14 \
			    -state normal \
			    -borderwidth 0 \
			    -relief flat \
                -selectmode single \
                ]  -in $selV::topGui.frame1.frame11 -row 1 -column 0 -padx 2 -sticky news

            grid [ttk::scrollbar $selV::topGui.frame1.frame11.vsb -orient vertical -command "$selV::topGui.frame1.frame11.lb1 yview"] -in $selV::topGui.frame1.frame11 -row 1 -column 1  -sticky ns 
            grid [ttk::scrollbar $selV::topGui.frame1.frame11.hsb -orient horizontal -command "$selV::topGui.frame1.frame11.lb1 xview"] -in $selV::topGui.frame1.frame11 -row 2 -column 0  -sticky ew 

            $selV::topGui.frame1.frame11.lb1 configcolumns 2 -editable false 0 -foreground black 2 -foreground black 0 -width 1 2 -align left
            $selV::topGui.frame1.frame11.lb1 configcolumns 1 -font {"Lucida Console" -12 bold}

    #### FRAME 3

    #### FRAME 4
    ## Set variables related to the list of option to edit the representantion
    variable colorMethodList {"Name" "Type" "Element" "ResName" "ResType" "ResID" "Chain" "SegName" "Conformation" "Molecule" "Secondary Structure" "Beta" "Occupancy" "Mass" "Charge" "Fragment" "Index" "Backbone" "Throb" "Volume" "ColorID 0 Blue" "ColorID 1 Red" "ColorID 2 Gray" "ColorID 3 Orange" "ColorID 4 Yellow" "ColorID 5 Tan" "ColorID 6 Silver" "ColorID 7 Green" "ColorID 8 White" "ColorID 9 Pink" "ColorID 10 Cyan" "ColorID 11 Purple" "ColorID 12 Lime" "ColorID 13 Mauve" "ColorID 14 Ochre" "ColorID 15 IceBlue" "ColorID 16 Black" "ColorID 17 Yellow2" "ColorID 18 Yellow3" "ColorID 19 Green2" "ColorID 20 Green3" "ColorID 21 Cyan2" "ColorID 22 Cyan3" "ColorID 23 Blue2" "ColorID 24 Blue3" "ColorID 25 Violet" "ColorID 26 Violet2" "ColorID 27 Magenta" "ColorID 28 Magenta2" "ColorID 29 Red2" "ColorID 30 Red3" "ColorID 31 Orange2" "ColorID 32 Orange3"}
    variable materialList [material list]
    variable drawMethodList {"Lines" "Bonds" "DynamicBonds" "HBonds" "Points" "VDW" "CPK" "Licorice" "Polyhedra" "Trace" "Tube" "Ribbons" "NewRibbons" "Cartoon" "NewCartoon" "PaperChain" "Twister" "QuickSurf" "MSMS" "NanoShaper" "Surf" "VolumeSlice" "Isosurface" "FieldLines" "Orbital" "Beads" "Dotted" "Solvent"}

    ## Get selection ID
    variable selectionID [lindex [$selV::topGui.frame1.frame11.lb1 get active] 0]

    #variable selectionEditor [string trim [molinfo top get "{selection $selV::selectionID}"] "{}"]
    variable curColor "Name"
    variable curDraw "Lines"
    variable curMaterial "Opaque"



    grid [ttk::frame $selV::topGui.frame4] -row 3 -column 0 -pady 0 -sticky news
    
        ## Selection editor


        ## Change representantion style
        grid [ttk::label $selV::topGui.frame4.title -text "Draw Syle"] -in $selV::topGui.frame4 -row 0 -column 0 -columnspan 2
        
        grid [ttk::label $selV::topGui.frame4.drawMethodLabel -text "Drawing Method: "] -in $selV::topGui.frame4 -row 1 -column 0 -sticky news
        grid [ttk::combobox $selV::topGui.frame4.drawMethod -state readonly -values $selV::drawMethodList -textvariable selV::curDraw] -in $selV::topGui.frame4 -row 1 -column 1 -sticky ew

        grid [ttk::label $selV::topGui.frame4.coloringMethodLabel -text "Coloring Method: "] -in $selV::topGui.frame4 -row 2 -column 0 -sticky news
        grid [ttk::combobox $selV::topGui.frame4.coloringMethod -state readonly -values $selV::colorMethodList -textvariable selV::curColor] -in $selV::topGui.frame4 -row 2 -column 1 -sticky news

        #grid [ttk::label $selV::topGui.frame4.materialLabel -text "Material: "] -in $selV::topGui.frame4 -row 3 -column 0 -sticky news
        #grid [ttk::combobox $selV::topGui.frame4.material -state readonly -values $selV::materialList -textvariable selV::curMaterial] -in $selV::topGui.frame4 -row 3 -column 1 -sticky news

        ##Commands
        bind $selV::topGui.frame4.coloringMethod <<ComboboxSelected>> "selV::validateSelectionEditor"
        bind $selV::topGui.frame4.drawMethod <<ComboboxSelected>> "selV::validateSelectionEditor"
 


	#### FRAME 5
	grid [ttk::frame $selV::topGui.frame5] -row 4 -column 0 -sticky news

		# Button
    
	    #grid [ttk::menubutton $selV::topGui.frame5.bt1 -text "Tools" -menu $selV::topGui.frame5.bt1.menu] -in $selV::topGui.frame5 -row 0 -column 1
        grid [ttk::button $selV::topGui.frame5.bt2 -text "Help" -command {selV::help}] -in $selV::topGui.frame5 -row 0 -column 2
        grid [ttk::button $selV::topGui.frame5.bt3 -text "Options" -width 8 -command {selV::optionsWindow}] -in $selV::topGui.frame5 -row 0 -column 3
       # grid [ttk::button $selV::topGui.frame5.bt4 -text "Exit" -width 6 -command {selV::exit}] -in $selV::topGui.frame5 -row 0 -column 3

		#menu $selV::topGui.frame5.bt1.menu -tearoff 0
		#$selV::topGui.frame5.bt1.menu add command -label "Reset view" -command {display resetview}
		#$selV::topGui.frame5.bt1.menu add command -label "Center atom" -command {mouse mode center}
		#$selV::topGui.frame5.bt1.menu add command -label "Bond, Angle, Dihedrals" -command {selV::badParams}
		#$selV::topGui.frame5.bt1.menu add command -label "Delete all labels" -command {selV::deleteAllLabels}
		#$selV::topGui.frame5.bt1.menu add command -label "Delete all graphics" -command {graphics 0 delete all}
        



   	#### GUI weight
  	grid columnconfigure $selV::topGui                      0 -weight 1
    grid columnconfigure $selV::topGui.frame0               1 -weight 1
    grid columnconfigure $selV::topGui.frame1.frame10       0 -weight 1
    grid columnconfigure $selV::topGui.frame1.frame11       0 -weight 1
    grid columnconfigure $selV::topGui.frame4               1 -weight 1
    grid columnconfigure $selV::topGui.frame5               0 -weight 1
    grid columnconfigure $selV::topGui.frame1.frame10.f0    0 -weight 1
    grid columnconfigure $selV::topGui.frame1.frame10.f1    1 -weight 1

    grid rowconfigure $selV::topGui                         1 -weight 1

    grid rowconfigure $selV::topGui.frame1.frame10          0 -weight 1
    grid rowconfigure $selV::topGui.frame1.frame10.f0       0 -weight 1

    grid rowconfigure $selV::topGui.frame1.frame11          1 -weight 2
    grid rowconfigure $selV::topGui.frame4                  0 -weight 3


    



    ### Create the Menu
    menu $selV::topGui.menu -tearoff 0
        $selV::topGui.menu add command -label "Show/Hide" -command {selV::clickListBox double}
        $selV::topGui.menu add command -label "Zoom" -command {selV::moveToSelection}
        $selV::topGui.menu add command -label "Number of Atoms" -command {selV::numberAtoms}
        $selV::topGui.menu add command -label "Delete" -command {selV::deleteSelection}

    #### Bindings
    bind $selV::topGui.frame0.cb1 <<ComboboxSelected>> selV::selectPDB
    bind $selV::topGui.frame1.frame10.f0.tree <<TreeviewSelect>> {selV::treeSelectItem 0}
    set tableListBody [$selV::topGui.frame1.frame11.lb1 bodytag]
    bind $selV::topGui.frame1.frame11.lb1  <<TablelistSelect>> {selV::clickListBox single}
    bind $tableListBody <Button-1> {selV::hideShow %x %y}
    #bind $tableListBody <Double-1> {selV::hideShow %x %y}
    bind $tableListBody <Button-2> {selV::rightClickMenu $selV::topGui.menu %x %y} 
    bind $tableListBody <Button-3> {selV::rightClickMenu $selV::topGui.menu %x %y}


    # History System
    bind $selV::topGui.frame1.frame10.f1.en1 <Key-Up> {selV::readHistory up}
    bind $selV::topGui.frame1.frame10.f1.en1 <Key-Down> {selV::readHistory down}

    # tab on entry to complete the text
    bind all <Tab> {break}
    bind $selV::topGui.frame1.frame10.f1.en1 <Tab> {
            set a [$selV::topGui.frame1.frame10.f1.en1 get]
			$selV::topGui.frame1.frame10.f1.en1 delete 0 end
			if {[string index $a end]!=" "} {$selV::topGui.frame1.frame10.f1.en1 insert end "$a "
			} else {$selV::topGui.frame1.frame10.f1.en1 insert end "$a"}
    }
    
	# Add the enter to apply or add changes
	bind $selV::topGui.frame1.frame10.f1.en1 <Return> {
		if {[lindex [$selV::topGui.frame1.frame10.f1.bt2 state] 0] == "active"} {
            selV::updateSelection
        } else {
            selV::addSelection
        }
	}


    #### Fill ComboBox with PDBs
    selV::PDBList

    #### Fill tree with Values
    if {$selV::layers!={} } {selV::fillTree}



}


proc selV::exit {} {
	wm withdraw $::selV::topGui
}

proc selV::optionsWindow {} {
    #### Check if the window exists
	if {[winfo exists $selV::optionsGui]} {wm deiconify $selV::optionsGui; return $selV::optionsGui}
	toplevel $selV::optionsGui
    wm attributes $selV::optionsGui -topmost 1

	#### Title of the windows
	wm title $selV::optionsGui "Options" ;# titulo da pagina


    #### Change the location of window
    # screen width and height
    set sWidth  [winfo vrootwidth  $selV::optionsGui]
    set sHeight [expr [winfo vrootheight $selV::optionsGui] - 80]

    #wm geometry window $VBox::topGui 40x59 0
    #wm geometry $selV::optionsGui 250x125+[expr $sWidth /2]+[expr $sHeight /2]

    #### FRAME 0
    grid [ttk::frame $selV::optionsGui.frame0] -row 0 -column 0 -padx 0 -pady 0 -sticky ew
        grid [ttk::checkbutton $selV::optionsGui.frame0.checkbt0 -variable selV::animationOnOff -text "Enable/Disable Zoom Animation"] -in $selV::optionsGui.frame0 -column 0 -row 0 -sticky news -columnspan 3
        grid [ttk::label $selV::optionsGui.frame0.l0 -text "Animation duration:"] -in $selV::optionsGui.frame0 -column 0 -row 1 -sticky news
        grid [ttk::entry $selV::optionsGui.frame0.en0 -textvariable selV::animationDuration -width 3 -validate key -validatecommand {string is double %P}] -in $selV::optionsGui.frame0 -column 1 -row 1 -sticky news
        grid [ttk::label $selV::optionsGui.frame0.l1 -text "seconds"] -in $selV::optionsGui.frame0 -column 2 -row 1 -sticky news
        grid [ttk::button $selV::optionsGui.frame0.bt0 -text "Apply" -command {destroy $selV::optionsGui}] -in $selV::optionsGui.frame0 -column 3 -row 1 -sticky news


#### FRAME 1
    grid [ttk::frame $selV::optionsGui.frame1] -row 1 -column 0 -padx 0 -pady 0 -sticky news

		grid [ttk::label $selV::optionsGui.frame1.l0 -text "________________________________________________\n\n Contact: \n"] -in $selV::optionsGui.frame1 -column 0 -row 0 -sticky news
		grid [ttk::label $selV::optionsGui.frame1.l1 -text " Nuno M. F. Sousa A. Cerqueira (nscerque@fc.up.pt)"] -in $selV::optionsGui.frame1 -column 0 -row 1 -sticky news
		grid [ttk::label $selV::optionsGui.frame1.l2 -text " Henrique S. Fernandes (henrique.fernandes@fc.up.pt)"] -in $selV::optionsGui.frame1 -column 0 -row 2 -sticky news
		
		grid [ttk::label $selV::optionsGui.frame1.l3 -text "\n REQUIMTE, University of Porto - Portugal\n"] -in $selV::optionsGui.frame1 -column 0 -row 3 -sticky news
    

#### FRAME 1
    grid [ttk::frame $selV::optionsGui.frame2] -row 2 -column 0 -padx 0 -pady 0 -sticky news
		
		grid [ttk::button $selV::optionsGui.frame2.bt0 -text "Exit" -command {if {[winfo exists $selV::optionsGui]} {wm withdraw $selV::optionsGui }}] -in $selV::optionsGui.frame2 -column 0 -row 0 -sticky news




    grid columnconfigure $selV::optionsGui                      0 -weight 1
    grid columnconfigure $selV::optionsGui.frame0               1 -weight 1
	grid columnconfigure $selV::optionsGui.frame2               0 -weight 1

}

proc selV::hideShow {x y} {
    $selV::topGui.frame1.frame11.lb1 selection clear top bottom
    set activecolumn [lindex [split [$selV::topGui.frame1.frame11.lb1 containingcell $x $y] ","] 1]
    set activeLine [expr [lindex [split [$selV::topGui.frame1.frame11.lb1 containingcell $x $y] ","] 0] + 1]

    if {$activecolumn == 1 && $activeLine < [$selV::topGui.frame1.frame11.lb1 size]} {
        $selV::topGui.frame1.frame11.lb1 selection set $activeLine
        selV::clickListBox double
    } else {}
    $selV::topGui.frame1.frame11.lb1 selection clear top bottom

}

#### DropMenu
proc selV::rightClickMenu {menu x y} {
    $selV::topGui.frame1.frame11.lb1 selection clear top bottom
    set activeLine [expr [lindex [split [$selV::topGui.frame1.frame11.lb1 containingcell $x $y] ","] 0] + 1]
    
    $selV::topGui.frame1.frame11.lb1 selection set $activeLine

    set x [winfo pointerx .]
    set y [winfo pointery .]

    tk_popup $menu $x $y
}



#### HELP GUI
 proc selV::help {} {
        set help $selV::topGui.about
	    if {[winfo exists $help]} {wm deiconify $help ; raise $help; return}
        toplevel $help
        wm title $help "Selections Manager Help"

        grid [text $help.tx -width 50 -bg yellow -height 25 -bg white \
                -yscrollcommand "$help.roll set" \
                -wrap word -cursor top_left_arrow] \
                -row 0 -column 0 -sticky news
        grid [scrollbar $help.roll -width 12 \
                -command "$help.tx yview"] -row 0 -column 1 -sticky news
        grid [button $help.close -text "Close" -borderwidth 6 \
                -command {if {[winfo exists $selV::topGui.about]} {wm withdraw $selV::topGui.about }}] -row 1 -column 0 \
                -columnspan 2 -sticky news
        grid rowconfigure    $help 0 -weight 1
        grid columnconfigure $help 0 -weight 1



$selV::topGui.about.tx tag configure keyword -font \
    {-family helvetica -size 10 -weight bold} \
	-foreground red

	$selV::topGui.about.tx tag configure title -font \
	    {-family helvetica -weight bold -size 12} \
		-foreground blue


$selV::topGui.about.tx insert end "VMD has a powerful atom selection language!\n"
$selV::topGui.about.tx insert end "\nIt is based around the assumption that every atom has a set of associated values which can be accessed through keywords."


$selV::topGui.about.tx insert end "\n\nThe SelectionManager plug-in was developed to turn the selection of atoms easier and at the same time allow the user to get in touch with these keywords and learn them."

$selV::topGui.about.tx insert end "\n\nThe SelectionManager also includes a new shell that allows:\n"

$selV::topGui.about.tx insert end "\n   - auto-complete keywords (using the TAB key).\n"

$selV::topGui.about.tx insert end "\n   - history of previous commands (using the Up arrow key).\n"

$selV::topGui.about.tx insert end "\n   - automatically recognizes if the selection has errors or not (if it is shown in red or balck color).\n"

$selV::topGui.about.tx insert end "\n\n Below are given some examples of usefull keywords used in VMD and can be used in the selectionManager plug-in."

$selV::topGui.about.tx insert end "\n\n\n # Standard selections\n" title

$selV::topGui.about.tx insert end "\n\nall" keyword
$selV::topGui.about.tx insert end "\nSelect all the atoms"

$selV::topGui.about.tx insert end "\n\nprotein" keyword
$selV::topGui.about.tx insert end "\nSelect all the atoms present in a protein macromolecule"

$selV::topGui.about.tx insert end "\n\nwater" keyword
$selV::topGui.about.tx insert end "\nSelect all the water atoms"

$selV::topGui.about.tx insert end "\n\nbackbone" keyword
$selV::topGui.about.tx insert end "\nSelect all the atoms from the backbone of a protein."

$selV::topGui.about.tx insert end "\n\nresname GLU" keyword
$selV::topGui.about.tx insert end "\nSelect all the atoms from the GLU (glutamate) amino acid residue."

$selV::topGui.about.tx insert end "\n\nresid 35" keyword
$selV::topGui.about.tx insert end "\nSelect all the atoms from the amino acid reside with the ID 35."

$selV::topGui.about.tx insert end "\n\nname CA" keyword
$selV::topGui.about.tx insert end "\nSelect all the atoms with the name CA (carbon alpha)"


$selV::topGui.about.tx insert end "\n\n\n # Composed selections\n" title


$selV::topGui.about.tx insert end "\n\n The VMd keywords can also be combined using the words 'and', 'not' and 'or'. Here are some examples."

$selV::topGui.about.tx insert end "\n\nnot protein" keyword
$selV::topGui.about.tx insert end "\nSelect all the atoms that do not belong to proteins"

$selV::topGui.about.tx insert end "\n\nall and not water" keyword
$selV::topGui.about.tx insert end "\nSelect all the atoms that are not water moelcules"

$selV::topGui.about.tx insert end "\n\nresname GLU and chain A" keyword
$selV::topGui.about.tx insert end "\nSelect all the atoms which belong to GLU (glutamates) and that belong to chain A of the protein"


$selV::topGui.about.tx insert end "\n\n\n # Advanced selections\n" title

$selV::topGui.about.tx insert end "\n\nall within 5 of resid 10" keyword
$selV::topGui.about.tx insert end "\nSelect all the atoms that are 5 Angstroms away from resid 10"

$selV::topGui.about.tx insert end "\n\nsame resname as (protein within 5 of resid 10)" keyword
$selV::topGui.about.tx insert end "\nSelect all the residues that are 5 Angstroms away from resid 10"

$selV::topGui.about.tx insert end "\n"
$selV::topGui.about.tx insert end "\n"
 }


#### GET PDBs loaded

proc selV::PDBList {} {
    # Add items
    set selV::layers ""
    if {[llength [molinfo list]]!=0} {

        # delete old item
        if {$selV::selection!=""} {
            ## modify representation if it already exists
            set repid [mol repindex top $selV::selection] 
            mol delrep $repid top
        }

        foreach mol [molinfo list] {
            set selV::layers [lappend selV::layers "[molinfo $mol get id]: [molinfo $mol get name]"]
        }
        # update comboBox values
        $selV::topGui.frame0.cb1 configure -values $selV::layers

        # Select the toplayer as the value on the comboBox
        $selV::topGui.frame0.cb1 set "[molinfo [molinfo top] get id]: [molinfo [molinfo top] get name]"

        ## fill the data off rep on the lisbbox
        selV::fillListbox
    } else {selV::cleanGui}


}

#### FILL TREE LIST with the protein Data
proc selV::fillTree {} {

    ## Remove tree values
    $selV::topGui.frame1.frame10.f0.tree delete [ $selV::topGui.frame1.frame10.f0.tree  children {}]

    ## How many chain are
    set chains ""
    set sel [atomselect top "all"]
    set data  [$sel get {chain} ]
    $selV::topGui.frame1.frame10.f0.tree insert {} end -id 0 -text "none"

    foreach chain $data {

        if {[lsearch $chains $chain]==-1} {
            ## Selects Chain
            set chains [lappend chains $chain]
			set count 1
			if {$chain!="X"} {
            $selV::topGui.frame1.frame10.f0.tree insert {} end -id [llength $chains] -text "chain $chain"

			set keywords {protein nucleic "not protein and not water and not nucleic" water}
			set keywordsName {protein nucleic other water}
			
			foreach name $keywords namePrint $keywordsName { 


            	## Adds the resname and resid of the protein part
            	set sel [atomselect top "(chain $chain and $name)"]
            	set residList ""
            	set datalist  [$sel get {resname resid residue type} ]
            	set id 1
            	foreach elem $datalist {
                	incr id
                	if {[lsearch $residList [lindex $elem 1]]==-1} {
                  		if {[llength $residList]==0} {$selV::topGui.frame1.frame10.f0.tree insert [llength $chains] end -id [llength $chains].$count -text "$namePrint"}
                  		set residList [lappend residList [lindex $elem 1]]
                  		$selV::topGui.frame1.frame10.f0.tree insert [llength $chains].$count end -id [llength $chains].$count.$id  -text "[lindex $elem 1] : [lindex $elem 0]"
                  		set id2 $id
                	}
                 		$selV::topGui.frame1.frame10.f0.tree insert [llength $chains].$count.$id2 end -id [llength $chains].$count.$id2.$id  -text "- [lindex $elem 3]"

            	}

			incr count
			}

			} else {

						$selV::topGui.frame1.frame10.f0.tree insert {} end -id [llength $chains] -text "Molecule"
							
						## Adds the resname and resid of the protein part
						set sel [atomselect top "all"]
						set datalist  [$sel get {type} ]
						set id 1
						foreach elem $datalist {
							incr id
							$selV::topGui.frame1.frame10.f0.tree insert [llength $chains] end -id [llength $chains].$id  -text "- $elem"
							incr count
						}
	
			}

			
			}

        }


}
  

proc selV::selectPDB {} {

    ## turn the comboBox PDB the topmolecule
    set selV::selection ""
    foreach mol [molinfo list] {
        set layer [molinfo $mol get name]
        set layersID [molinfo $mol get id]

        if { [lindex [$selV::topGui.frame0.cb1 get] 1]==$layer} {
                ## delete any previous selection representation before the change
                if {$selV::selection!=""} {
                    set repid [mol repindex top $selV::selection] 
                    mol delrep $repid top
                }
            mol top $layersID
            break
        }

    }


    ## fill the data on the tree
    selV::fillTree 

    ## fill the data off rep on the lisbbox
    selV::fillListbox

    ## reset view
    #display resetview
}


proc selV::addSelection {} {

    if {[llength [molinfo list]]!=0 && $selV::selection!=""} {

        if {$selV::widget=="tree"} {
            # tree selecttion 
            selV::treeSelectItem 1
            mol color colorid 4
            set selV::selection ""
            selV::fillListbox 
        
		} else {
            if {$selV::entrySel!="none"} {
                selV::entrySelection $selV::entrySel 1
                mol color colorid 4
                set selV::selection ""
                selV::fillListbox 
            }
           
        }

    } 


     ### Add selection to history
     lappend selV::selectionHistory $selV::customSelection


    ## Clear selection
    set selV::customSelection ""

}

proc selV::numberAtoms {} {
    set item [$selV::topGui.frame1.frame11.lb1 curselection]

    set text [string trim [lindex [$selV::topGui.frame1.frame11.lb1 get $item] 2] "{}"]
    set selection [atomselect top "$text"]

    set numAtoms [$selection num]

    tk_messageBox -parent $selV::topGui -icon info -title "Number of Atoms" -type ok -message "Current selection has $numAtoms atom(s)." 
}

proc selV::deleteSelection {} {

    ## get item
    set item [$selV::topGui.frame1.frame11.lb1 curselection]
    #set text [$selV::topGui.frame1.frame11.lb1 get $item]
    if {$item!=""} {
        mol delrep $item top
        selV::fillListbox
    }
    $selV::topGui.frame1.frame11.lb1 selection set [expr $item -1]


    $selV::topGui.frame1.frame11.lb1 selection clear top bottom
}

proc selV::string_diff {str1 str2} {
    for {set i 0} {$i < [string length $str1]} {incr i} {
        if {[string index $str2 $i] ne [string index $str1 $i]} {
            return [string range $str2 $i end]
        }
    }
    return [string range $str2 $i end]
}


proc selV::treeSelectItem {opt} {


    if {[llength [molinfo list]]!=0} {

            set list [$selV::topGui.frame1.frame10.f0.tree selection]
            
            set optimizedList {}
            foreach element $list {
                set element [split $element "."]
                lappend optimizedList $element
            }
        
            set optSelection ""
            for {set index 0} { $index <= [lindex [lindex $optimizedList end] 0] } { incr index } {
                set a [lsearch -index 0 -all $optimizedList $index]
                
                if {$a != ""} {
                    set [subst list$index] {}
                    foreach b $a {
                        lappend [subst list$index] [lindex $optimizedList $b]
                    }
        
        
                    if {$optSelection != ""} {
                        append optSelection " or "
                    }

                    if {[$selV::topGui.frame1.frame10.f0.tree item $index -text] == "Molecule"} {
                        append optSelection "(all"
                    } else {
                        append optSelection "([$selV::topGui.frame1.frame10.f0.tree item $index -text]"
                    }
        
        
                    if {[llength [lindex $optimizedList [lsearch -index 0 $optimizedList $index]]] > 1} {
                    
                        #### Protein, Other and Water section
                        set listOfIndexes {}
                        foreach element [subst $[subst list$index]] {
                            set subindex [lindex $element 1]
                            if {[lsearch $listOfIndexes $subindex] == -1} {
                                lappend listOfIndexes $subindex
                            }
        
                            lappend [subst sublist$subindex] $element
                        }
        
                        set status 0
                        set statusA 0
                        foreach element $listOfIndexes {
                            if {$element != ""} {
                                if {$status == 0} {
                                    append optSelection " and ("
        
                                    set status 1
                                }
        
                                append optSelection "("
        
                                set text [$selV::topGui.frame1.frame10.f0.tree item $index.$element -text]
                                if {$text == "other" } {
                                    set text "(not protein and not water and not nucleic)"
                                } elseif {[string range $text 0 0] == "-"} {
                                    set text "index [expr $element - 2]"
                                }
                                append optSelection $text
                                
                            if {[llength [lindex $optimizedList [lsearch -index 0 $optimizedList $index]]] > 2} {    
                                #### Residues
                                set residuesTreeIndexes [lsearch -index 1 -all [lsearch -index 0 -all -inline $optimizedList $index] $element]

                                set listOfIndexesResid {}
                                foreach a $residuesTreeIndexes {
                                    set subsubindex [lindex [lindex [lsearch -index 0 -all -inline $optimizedList $index] $a] 2]
        
                                    if {[lsearch $listOfIndexesResid $subsubindex] == -1} {
                                        lappend listOfIndexesResid $subsubindex
                                    }
        
                                    lappend [subst sublist$subsubindex] $subsubindex
                                }
        
                                set statusResid 0
                                set statusResidA 0
                                foreach b $listOfIndexesResid {
                                    if {$b != ""} {
                                        if {$statusResid == 0} {
                                            append optSelection " and ("
        
                                            set statusResid 1
                                        }
        
                                        set text [lindex [split [$selV::topGui.frame1.frame10.f0.tree item $index.$element.$b -text] " : "] 0]
                                        append optSelection "(resid $text"
        
        
        
                                            
                                        if {[llength [lindex $optimizedList [lsearch -index 0 $optimizedList $index]]] > 3} {
                                        
                                            #### Atom
                                            set atomsTreeIndexes [lsearch -index 2 -all [lsearch -index 1 -all -inline [lsearch -index 0 -all -inline $optimizedList $index] $element] $b]
        
                                            set listOfIndexesAtom {}
                                            foreach a $atomsTreeIndexes {
                                                set subsubsubindex [lindex [lindex [lsearch -index 1 -all -inline [lsearch -index 0 -all -inline $optimizedList $index] $element] $a] 3]
        
                                                if {[lsearch $listOfIndexesAtom $subsubsubindex] == -1} {
                                                    lappend listOfIndexesAtom $subsubsubindex
                                                }
        
                                                lappend [subst sublist$subsubsubindex] $subsubsubindex
                                            }
        
                                            set statusAtom 0
                                            set statusAtomA 0
        
                                            foreach c $listOfIndexesAtom {
                                                if {$c != ""} {
                                                    set text [lindex [split [$selV::topGui.frame1.frame10.f0.tree item $index.$element.$b.$c -text] " "] 1]
                                                    
                                                    if {$statusAtom == 0} {
                                                        append optSelection " and ("
        
                                                        set statusAtom 1
                                                        append optSelection "name $text"
                                                    } else {
                                                        append optSelection " $text"
                                                    }
        
                                                    set statusAtomA 1
        
                                                }
                                            }
                                            
                                            if {$statusAtomA == 1} {
                                                append optSelection ")"
                                            }
                                        }
        
                                        append optSelection ")"
        
                                        if {[expr [lsearch $listOfIndexesResid $b] + 1] == [llength $listOfIndexesResid]} {
                                            # Do nothing
                                        } else {
                                            append optSelection " or "
                                        }
        
                                        set statusResidA 1
        
                                    }
                                }
        
                                if {$statusResidA == 1} {
                                    append optSelection ")"
                                }
        
                            }
        
        
        
        
                                append optSelection ")"
        
                                if {[expr [lsearch $listOfIndexes $element] + 1] == [llength $listOfIndexes]} {
                                    # Do nothing
                                } else {
                                    append optSelection " or "
                                }
        
                                set statusA 1
        
                                
        
                            }
        
                        
                        }
        
        
        
                        if {$statusA == 1} {
                            append optSelection ")"
                        }
        
                    }
        
                    append optSelection ")"
        
                }
            }
        
        
            selV::changeRepresentation $optSelection $opt
        
            ## Update text shown of the custom selection entry
            set selV::customSelection $optSelection
        
        } else {
            selV::cleanGui
    }

set selV::widget tree

}


proc selV::changeRepresentation {selectionTotal opt} {
	
	
	if {$selectionTotal=="(Molecule)" } {set selectionTotal "(all)"}

    ## Change representation

    # delete old item
    if {$selV::selection!=""} {
        ## modify representation if it already exists
        set repid [mol repindex top $selV::selection] 
        mol delrep $repid top
    }

    # create a new rep
    set atomNum [[atomselect top $selectionTotal] num ]

    mol selection $selectionTotal

    # Change atom representation based on the number of atoms in the selection
    set atomNum [[atomselect top $selectionTotal] num ]

    if {$atomNum>1000} { mol representation Cartoon
    } elseif {$atomNum<4} {mol representation VDW
    } else {mol representation Licorice 0.300000 8.000000 6.000000}

    # change color if is selection or add selection
    if {$opt==1} { mol color Name
    } else {mol color ColorID 4}

    mol addrep top

    # memorize rep details
    set repid [expr [molinfo top get numreps] - 1]
    set repname [mol repname top $repid]
    set selV::selection $repname
}



proc selV::fillListbox {} {
    ## clean listbox
     $selV::topGui.frame1.frame11.lb1 delete 0 [ $selV::topGui.frame1.frame11.lb1 size]
    
    ## Add items
    set repname ""
    for {set i 0} {$i < [molinfo top get numreps]} {incr i} {
        lassign [molinfo top get "{rep $i} {selection $i} "] a b 

        ## all but not the one equal to the one of the selections
        set repid [expr [molinfo top get numreps] -1]
        set repname [mol repname top $i]
        if {$repname!=$selV::selection} {
            if {[mol showrep top $i]==0} {
                $selV::topGui.frame1.frame11.lb1 insert end [list "$i" "| |" "$b"]
                $selV::topGui.frame1.frame11.lb1 rowconfigure $i -foreground red
                } else {
                    $selV::topGui.frame1.frame11.lb1 insert end [list "$i" "|X|" "$b"]
                    $selV::topGui.frame1.frame11.lb1 rowconfigure $i -foreground black
                    }
        }

    }

}

proc selV::clickListBox {opt} {

    if {[llength [molinfo list]]!=0} {

        ## get item
        set item [$selV::topGui.frame1.frame11.lb1 curselection]
        set text [$selV::topGui.frame1.frame11.lb1 get $item]

        set selV::item $item

        set selV::customSelection [string trim [lindex $text 2] "{}"]
        $selV::topGui.frame1.frame10.f1.bt2 configure -state active

        set selV::selectionID $item

        set selV::curColor [string trim [molinfo top get "{color $item}"] "{}"]
        set selV::curDraw [lindex [string trim [molinfo top get "{rep $item}"] "{}"] 0]
        set selV::curMaterial "Opaque"

        #ver se o numero de items da listabox não é menor do que o numero de items

        if {$item<=[expr [molinfo top get numreps]-1] } {
            $selV::topGui.frame1.frame11.lb1 selection set $item 
        } else { selV::fillListbox; set item [expr [molinfo top get numreps]-1] }

        if {$opt=="double"} {
            if {[mol showrep top $item]==0} {
                mol showrep top $item 1
                $selV::topGui.frame1.frame11.lb1 rowconfigure $item -foreground black
                $selV::topGui.frame1.frame11.lb1 rowconfigure $item -selectforeground black
                $selV::topGui.frame1.frame11.lb1 configcells [subst $item],1 -text "|X|"
            } else {
                mol showrep top $item 0
                $selV::topGui.frame1.frame11.lb1 rowconfigure $item -foreground red  
                $selV::topGui.frame1.frame11.lb1 rowconfigure $item -selectforeground red
                $selV::topGui.frame1.frame11.lb1 configcells [subst $item],1 -text "| |"
            }

            $selV::topGui.frame1.frame11.lb1 selection clear top bottom

        } else {

            if {[mol showrep top $item]==1} {
                $selV::topGui.frame1.frame11.lb1 rowconfigure $item -selectforeground black
            } else {
                $selV::topGui.frame1.frame11.lb1 rowconfigure $item -selectforeground red
            }

            $selV::topGui.frame1.frame11.lb1 selection set $item 

            #set selV::customSelection [lindex $text 2]

            # select item no rep
            # modselect rep_number molecule_number select_method
        }

        # See item that was selected
        $selV::topGui.frame1.frame11.lb1 see $item

    } else {selV::cleanGui}

    

    
}

proc selV::edit {} {
    set item [$selV::topGui.frame1.frame11.lb1 curselection]
    if {$item!=""} {
           if {[menu graphics status]=="off"} {menu graphics on}
    }


}

proc selV::updateSelection {} {
    mol modselect $selV::item top $selV::customSelection

    ## Update list of representantions
    selV::fillListbox

     ### Add selection to history
     lappend selV::selectionHistory $selV::customSelection

    set selV::customSelection ""
    $selV::topGui.frame1.frame10.f1.bt2 configure -state disabled
}

proc selV::entrySelection {selection opt} {
    set error ""
    if {$selV::layers!={}} {
        catch {set error [atomselect top "$selection"]} atomselect
        ## see if the text give error or not
    
        if {$error==""} {
            #turn widget red
            ttk::style configure entry -foreground red  -borderwidth 2 -padding 0
            #set selV::selection ""
            selV::changeRepresentation "none" 0
            set selV::entrySel "none"


        } else {
            ttk::style configure entry -foreground black  -borderwidth 2 -padding 0
            ## put the selection in yellow
            set selV::entrySel $selection
            selV::changeRepresentation $selection $opt
        }

        ## avaliate the text
        # if there is not error turn it in yellow
        # otherwise turn the text red
        set selV::widget entry
    }
        return 1

}
proc selV::about {} {
    tk_messageBox -icon info -title Help -parent $selV::topGui -type ok -message "Selection Viewer provides an easy GUI to handle molecule selections.\n\nContact: \nNuno Sousa Cerqueira (nscerque@fc.up.pt)\nHenrique S. Fernandes (henrique.fernandes@fc.up.pt) \nFaculty of Sciences - University of Porto - Portugal" 
}


proc selV::cleanGui {} {
    $selV::topGui.frame1.frame10.f0.tree delete [ $selV::topGui.frame1.frame10.f0.tree  children {}]
    $selV::topGui.frame1.frame11.lb1 delete 0 end
    set  $selV::layers ""
    $selV::topGui.frame0.cb1 configure -values $selV::layers
    $selV::topGui.frame0.cb1 set ""
}

proc selV::start {} {

   
#### Check if the window exists
if {[winfo exists $::selV::topGui]} {
	wm deiconify $::selV::topGui
	update
	return $::selV::topGui
	}

    ##### START GUI
    selV::startGui

   	return $::selV::topGui
}


proc selV::validateSelectionEditor {} {
    mol modcolor $selV::selectionID top "$selV::curColor"
    mol modmaterial $selV::selectionID top "$selV::curMaterial"
    mol modstyle $selV::selectionID top "$selV::curDraw"

    selV::selectPDB
}


proc selV::moveToSelection {} {
    set item [$selV::topGui.frame1.frame11.lb1 curselection]
    set text [string trim [lindex [$selV::topGui.frame1.frame11.lb1 get $item] 2] "{}"]
    set selection [atomselect top "$text"]

    set centerMass [selV::massCenter $selection]

    ## Center on selection
    set x [expr [lindex $centerMass 0] * -1]
    set y [expr [lindex $centerMass 1] * -1]
    set z [expr [lindex $centerMass 2] * -1]
    #molinfo top set center_matrix "{{1 0 0 $x} {0 1 0 $y} {0 0 1 $z} {0 0 0 1}}"


    ## Zoom
    if {[$selection num] > 1} {
        set max 0
        foreach atom [$selection get {x y z}] {
            set x2 [lindex $atom 0] 
            set y2 [lindex $atom 1] 
            set z2 [lindex $atom 2] 
    
            set dist [expr (($x2-[lindex $centerMass 0])*($x2-[lindex $centerMass 0]) + ($y2-[lindex $centerMass 1])*($y2-[lindex $centerMass 1]) + ($z2-[lindex $centerMass 2])*($z2-[lindex $centerMass 2]))]
            if {$dist > $max} { 
                set max $dist 
            } 
        }

        set zoom [expr 1 / sqrt($max)]
    } else {
        set zoom 0.5
    }

    #molinfo top set scale_matrix "{{$zoom 0 0 0} {0 $zoom 0 0} {0 0 $zoom 0} {0 0 0 1}}"

    set rotateMatrix [molinfo top get rotate_matrix]

    if {$selV::animationOnOff == 1} {
        ::selV::moveToViewPoint "{{1 0 0 $x} {0 1 0 $y} {0 0 1 $z} {0 0 0 1}} $rotateMatrix {{$zoom 0 0 0} {0 $zoom 0 0} {0 0 $zoom 0} {0 0 0 1}} {{1 0 0 0} {0 1 0 0} {0 0 1 0} {0 0 0 1}}"
    } else {
        molinfo top set center_matrix "{{1 0 0 $x} {0 1 0 $y} {0 0 1 $z} {0 0 0 1}}"
        molinfo top set scale_matrix "{{$zoom 0 0 0} {0 $zoom 0 0} {0 0 $zoom 0} {0 0 0 1}}"
    }


}

proc selV::massCenter {selection} {
        # set the geometrical center to 0
        set gc [veczero]
        # [$selection get {x y z}] returns a list of {x y z} 
        #    values (one per atoms) so get each term one by one
        foreach coord [$selection get {x y z}] {
           # sum up the coordinates
           set gc [vecadd $gc $coord]
        }
        # and scale by the inverse of the number of atoms
        return [vecscale [expr 1.0 /[$selection num]] $gc]
}


##### Viewpoints procs

proc selV::getViewPoints {} {

    puts "##### HELP : ######"
	# get viewpoint start
	set viewpointStart [molinfo [molinfo top get id] get {center_matrix rotate_matrix scale_matrix global_matrix}]

	set ::VCR::viewpoints(1,0) "{ [lindex $viewpointStart 1] }"
	set ::VCR::viewpoints(1,1) "{ [lindex $viewpointStart 0] }"
	set ::VCR::viewpoints(1,2) "{ [lindex $viewpointStart 2] }"
	set ::VCR::viewpoints(1,3) "{ [lindex $viewpointStart 3] }"
	set ::VCR::viewpoints(1,4) { 0 }

	set viewpointStart [molinfo [molinfo top get id] get {center_matrix rotate_matrix scale_matrix global_matrix}]
	puts " vmdTutor::setview \"$viewpointStart\""
	puts "\n"
	puts "vmdTutor::movie \"$viewpointStart\""
}


proc selV::moveToViewPoint {viewpointsEnd} {

	# do not allow VCR to change representations
	::VCR::disableRepChanges

	# get viewpoint start
	set viewpointStart [molinfo [molinfo top get id] get {center_matrix rotate_matrix scale_matrix global_matrix}]
	set viewpointStart [molinfo [molinfo top get id] get {center_matrix}]

	set ::VCR::viewpoints(1,0) "{ [lindex $viewpointStart 1] }"
	set ::VCR::viewpoints(1,1) "{ [lindex $viewpointStart 0] }"
	set ::VCR::viewpoints(1,2) "{ [lindex $viewpointStart 2] }"
	set ::VCR::viewpoints(1,3) "{ [lindex $viewpointStart 3] }"
	set ::VCR::viewpoints(1,4) { 0 }

	set ::VCR::viewpoints(2,0) "{ [lindex $viewpointsEnd 1] }"
	set ::VCR::viewpoints(2,1) "{ [lindex $viewpointsEnd 0] }"
	set ::VCR::viewpoints(2,2) "{ [lindex $viewpointsEnd 2] }"
	set ::VCR::viewpoints(2,3) "{ [lindex $viewpointsEnd 3] }"
	set ::VCR::viewpoints(2,4) { 0 }

	## Add All Viewpoints to VCR
	set ::vcr_gui::vplist [::VCR::list_vps]

	#move to state num
	::VCR::movetime_vp here 2 $selV::animationDuration
}


##### Entry History 
proc selV::readHistory {opt} {
    if {$selV::selectionHistoryID == ""} {
         set selV::selectionHistoryID [llength $selV::selectionHistory]
    } else {}

    if {$selV::selectionHistoryID > [llength $selV::selectionHistory]} {
             set selV::selectionHistoryID ""
    } else {
        if {$opt == "up" && $selV::selectionHistoryID > 0} {
             set selV::selectionHistoryID [expr $selV::selectionHistoryID - 1]
             set selV::customSelection [lindex $selV::selectionHistory $selV::selectionHistoryID]
 
        } elseif {$opt == "down"} {
             set selV::selectionHistoryID [expr $selV::selectionHistoryID + 1]
             set selV::customSelection [lindex $selV::selectionHistory $selV::selectionHistoryID]
        } else {}
    }
}

  


##### AutoComplete

# Autocompletes the words in a entry

proc selV::autocomplete {win action validation value valuelist} {
	
	# only searches the last word if more than one word exists
	set value1 $value; set value0 ""

	if {[llength $value] >=2 && [string index $value end]!=" "} {
		
		set value1 [lindex $value [expr [llength $value]-1]]
		set value0 "[string range $value 0 [expr [string length $value] - [string length " $value1"]-1]] "
		
	} else {set value1 $value}
	
	# change last word according to the valuelist

	if {$action == 1 & $value1!= {} & [set pop [lsearch -inline $valuelist $value1*]] != {}} {
		set value1 "$value1"
		$win delete 0 end;  $win insert end "$value0$pop"
		$win selection range [string length "$value0$value1"] end
		$win icursor [string length "$value0$value1"]
	} else {
		$win selection clear
	}
	after idle [list $win configure -validate $validation]
	return 1
}


#### Delete All Labels
proc selV::deleteAllLabels {} {
    label delete Atoms All
    label delete Bonds All
    label delete Angles All
    label delete Dihedrals All
    label delete Springs All
}



proc selV::badParams {} {

	#### Check if the window exists
	if {[winfo exists $::selV::topGui.badParams]} {wm deiconify $::selV::topGui.badParams ; selV::badPickAtom; return $::selV::topGui.badParams}
	toplevel $::selV::topGui.badParams
	wm attributes $::selV::topGui.badParams -topmost yes

	#### Title of the window
	wm title $::selV::topGui.badParams "Measure Bond, Angle and Dihedral Angles" ;# titulo da pagina
	wm resizable $::selV::topGui.badParams 0 0


    #### GUI

		## Frame 0 - LABELS
		grid [ttk::frame $::selV::topGui.badParams.frame0] -row 1 -column 0 -padx 1 -pady 1 -sticky news
		

			grid [ttk::label $::selV::topGui.badParams.frame0.label0 -text "Click on Atoms of the VMD window to get Bond, Angle and \nDihedral parameters."] \
				-in $::selV::topGui.badParams.frame0 \
				-row 0 -column 0
						

		## Frame 1  - BAD PARABETERS
		grid [ttk::frame $::selV::topGui.badParams.frame1] -row 0 -column 0 -padx 1 -pady 1 -sticky news


			# LABELS
			
			foreach a "Param Atom Index Type Resid Value Units" column "0 1 2 3 4 5 6" {

			grid [ttk::label $::selV::topGui.badParams.frame1.label_$a -text "$a"] \
				-in $::selV::topGui.badParams.frame1 \
				-row 0 -column $column
						
			}
						
			# BAD PARAMETERS	
			
			foreach a "None Bond Angle Dihedral" row "1 2 3 4" {
				
				
				
				# label BOND ANGLE DIHEDRAL
				if {$a=="None"} {
				grid [ttk::label $::selV::topGui.badParams.frame1.label_$a -text ""] \
					-in $::selV::topGui.badParams.frame1 \
					-row $row -column 0
				} else {
				grid [ttk::label $::selV::topGui.badParams.frame1.label_$a -text "$a"] \
									-in $::selV::topGui.badParams.frame1 \
									-row $row -column 0
				}
				
				# entry Label 
				grid [ttk::label $::selV::topGui.badParams.frame1.label1_$a -text $row] \
				-in $::selV::topGui.badParams.frame1 \
				-row $row -column 1		
				
				# entry Index 
				grid [ttk::entry $::selV::topGui.badParams.frame1.entryIndex_$a -width 5 -style selV.TEntry] \
					-in $::selV::topGui.badParams.frame1 \
					-row $row -column 2 -padx 1 -pady 1

				# entry 1 - INDEX SELECTION
				grid [ttk::entry $::selV::topGui.badParams.frame1.entryAtom_$a -width 5 -style selV.TEntry] \
					-in $::selV::topGui.badParams.frame1 \
					-row $row -column 3 -padx 1 -pady 1	
					
					
				# entry 3 - INDEX SELECTION
				grid [ttk::entry $::selV::topGui.badParams.frame1.entryResid_$a -width 5 -style selV.TEntry] \
					-in $::selV::topGui.badParams.frame1 \
					-row $row -column 4 -padx 1 -pady 1	



				if {$row>=2} {
				
					# entry 2 DISTANCE, ANGLE, DIHEDRAL
					grid [ttk::entry $::selV::topGui.badParams.frame1.entryValue_$a -width 10 -style selV.TEntry] \
						-in $::selV::topGui.badParams.frame1 \
						-row $row -column 5 -padx 1 -pady 1	
		
		
					# Units
					if {$row==3 || $row==4} {set text "Degrees"
					} else {set text "Angstroms"}
					
					grid [ttk::label $::selV::topGui.badParams.frame1.units_$a -text $text] \
					-in $::selV::topGui.badParams.frame1 \
					-row $row -column 6 -sticky w
					
				}
				
			}
			
		## Frame 2 - Buttons
		grid [ttk::frame $::selV::topGui.badParams.frame2] -row 2 -column 0 -padx 1 -pady 1 -sticky news
				
				grid [ttk::button $::selV::topGui.badParams.frame2.button_1 -text "Close" \
							-command {mouse mode rotate;trace vdelete ::vmd_pick_atom w selV::atomPickedBAD; wm withdraw $::selV::topGui.badParams;
							    if {[winfo exists $::selV::topGui.badParams]} {wm withdraw $::selV::topGui.badParams}} \
                                -style selV.TButton \
                                ] -in $::selV::topGui.badParams.frame2 \
							-row 0 -column 3 -pady 10 -padx 20
							
				grid [ttk::button $::selV::topGui.badParams.frame2.button_2 -text "Assign Atoms" \
					-command {mouse mode pick} \
                    -style selV.TButton \
                    ] -in $::selV::topGui.badParams.frame2 \
					-row 0 -column 1 -pady 10 -padx 20
											
											
				grid [ttk::button $::selV::topGui.badParams.frame2.button_3 -text "Delete Data" \
					-command {selV::deleteAll} \
                    -style selV.TButton \
                    ] -in $::selV::topGui.badParams.frame2 \
					-row 0 -column 2 -pady 10 -padx 20
	
	
	
	label textthickness 2
	selV::badPickAtom
				
}


proc selV::badPickAtom {} {
	
		## Trace the variable to run a command each time a atom is picked
	    trace variable ::vmd_pick_atom w selV::atomPickedBAD
		
		## Activate atom pick
		mouse mode pick
}


proc selV::deleteAll {} {
	
	
		$::selV::topGui.badParams.frame1.entryIndex_None delete 0 end
		$::selV::topGui.badParams.frame1.entryAtom_None delete 0 end
		$::selV::topGui.badParams.frame1.entryResid_None delete 0 end
		
		$::selV::topGui.badParams.frame1.entryIndex_Bond delete 0 end
		$::selV::topGui.badParams.frame1.entryAtom_Bond delete 0 end
		$::selV::topGui.badParams.frame1.entryResid_Bond delete 0 end
		$::selV::topGui.badParams.frame1.entryValue_Bond delete 0 end
				 
		$::selV::topGui.badParams.frame1.entryIndex_Angle delete 0 end
		$::selV::topGui.badParams.frame1.entryAtom_Angle delete 0 end
		$::selV::topGui.badParams.frame1.entryResid_Angle delete 0 end
		$::selV::topGui.badParams.frame1.entryValue_Angle delete 0 end 
		
		$::selV::topGui.badParams.frame1.entryIndex_Dihedral delete 0 end
		$::selV::topGui.badParams.frame1.entryAtom_Dihedral delete 0 end
		$::selV::topGui.badParams.frame1.entryResid_Dihedral delete 0 end
		$::selV::topGui.badParams.frame1.entryValue_Dihedral delete 0 end
		
		
		# clean graphics
		foreach a $selV::graphicsID {
			foreach b $a {
				graphics [molinfo top] delete $b
			}
		} 
		
		#delete labels
		
		label delete Atoms all 
		label delete Bonds all 
		label delete Angles all 
		label delete Dihedrals all 
				
		
		# delete data
		set selV::graphicsID ""
		set selV::pickedAtomsBAD ""

	
}

proc selV::atomPickedBAD {args} {
	
	
	if {[lsearch $selV::pickedAtomsBAD $::vmd_pick_atom]==-1} {


		if {[llength $selV::pickedAtomsBAD]>=4 || [llength $selV::pickedAtomsBAD]==0} {
		
		
		#Delete Index Atom Resid Param Value Check
		selV::deleteAll
	
		# Add the first atom	
		set selV::pickedAtomsBAD $::vmd_pick_atom
	
	
	} else {lappend selV::pickedAtomsBAD $::vmd_pick_atom}
	
	
	# Put Values in the correct place
	
	if {[llength $selV::pickedAtomsBAD]==1} {
		
		# First Atom
		$::selV::topGui.badParams.frame1.entryIndex_None insert 0 "[lindex $selV::pickedAtomsBAD 0]"
		set sel [atomselect top "index [lindex $selV::pickedAtomsBAD 0]"] 
		$::selV::topGui.badParams.frame1.entryAtom_None insert 0 "[$sel get name]"
		$::selV::topGui.badParams.frame1.entryResid_None insert 0 "[$sel get resid]"	
		# Draw
			set mem [selV::sphere [lindex $selV::pickedAtomsBAD 0] red]
		
		set selV::graphicsID [lappend selV::graphicsID "$mem"]

				


	} elseif {[llength $selV::pickedAtomsBAD]==2} {
		
		
		#BOND
		$::selV::topGui.badParams.frame1.entryIndex_Bond insert 0 "[lindex $selV::pickedAtomsBAD 1]"
		set sel [atomselect top "index [lindex $selV::pickedAtomsBAD 1]"] 
		$::selV::topGui.badParams.frame1.entryAtom_Bond insert 0 "[$sel get name]"
		$::selV::topGui.badParams.frame1.entryResid_Bond insert 0 "[$sel get resid]"
	
		# Value
		set value [strictformat %7.2f [measure bond  "[lindex $selV::pickedAtomsBAD 0] [lindex $selV::pickedAtomsBAD 1]"] ]
		$::selV::topGui.badParams.frame1.entryValue_Bond insert 0 "$value"
		label add Bonds [molinfo top]/[lindex $selV::pickedAtomsBAD 0] [molinfo top]/[lindex $selV::pickedAtomsBAD 1]


		# Draw
		set mem [selV::sphere [lindex $selV::pickedAtomsBAD 1] white]
		set mem1 [selV::line [lindex $selV::pickedAtomsBAD 0] [lindex $selV::pickedAtomsBAD 1] white]
		
		
		set selV::graphicsID [lappend selV::graphicsID "$mem $mem1"]

	

	} elseif {[llength $selV::pickedAtomsBAD]==3} {
		
		#ANGLE
		
		$::selV::topGui.badParams.frame1.entryIndex_Angle insert 0 "[lindex $selV::pickedAtomsBAD 2]"
		
		set sel [atomselect top "index [lindex $selV::pickedAtomsBAD 2]"] 
		$::selV::topGui.badParams.frame1.entryAtom_Angle insert 0 "[$sel get name]"
		$::selV::topGui.badParams.frame1.entryResid_Angle insert 0 "[$sel get resid]"
		
		# Value
		set value [strictformat %7.2f [measure angle "[lindex $selV::pickedAtomsBAD 0] [lindex $selV::pickedAtomsBAD 1] [lindex $selV::pickedAtomsBAD 2]"] ]
		$::selV::topGui.badParams.frame1.entryValue_Angle insert 0 "$value"
		
		label add Angles [molinfo top]/[lindex $selV::pickedAtomsBAD 0] [molinfo top]/[lindex $selV::pickedAtomsBAD 1] [molinfo top]/[lindex $selV::pickedAtomsBAD 2]

		
		# Draw
		
		set mem [selV::sphere [lindex $selV::pickedAtomsBAD 2] yellow]
		set mem1 [selV::triangle [lindex $selV::pickedAtomsBAD 0] [lindex $selV::pickedAtomsBAD 1] [lindex $selV::pickedAtomsBAD 2] yellow]
		
		
		set selV::graphicsID [lappend selV::graphicsID "$mem $mem1"]
		
	} elseif {[llength $selV::pickedAtomsBAD]==4} {
		
		#DIHEDRAL
		
		$::selV::topGui.badParams.frame1.entryIndex_Dihedral insert 0 "[lindex $selV::pickedAtomsBAD 3]"
		
		set sel [atomselect top "index [lindex $selV::pickedAtomsBAD 3]"] 
		$::selV::topGui.badParams.frame1.entryAtom_Dihedral insert 0 "[$sel get name]"
		$::selV::topGui.badParams.frame1.entryResid_Dihedral insert 0 "[$sel get resid]"
	
	
		# value
		set value [strictformat %7.2f [measure dihed "[lindex $selV::pickedAtomsBAD 0] [lindex $selV::pickedAtomsBAD 1] [lindex $selV::pickedAtomsBAD 2] [lindex $selV::pickedAtomsBAD 3]"] ]
		$::selV::topGui.badParams.frame1.entryValue_Dihedral insert 0 "$value"
		
		label add Dihedrals [molinfo top]/[lindex $selV::pickedAtomsBAD 0] [molinfo top]/[lindex $selV::pickedAtomsBAD 1] [molinfo top]/[lindex $selV::pickedAtomsBAD 2]  [molinfo top]/[lindex $selV::pickedAtomsBAD 3]
		
		# Draw
		set mem [selV::sphere [lindex $selV::pickedAtomsBAD 3] cyan]
		#set mem1 [selV::triangle [lindex $selV::pickedAtomsBAD 1] [lindex $selV::pickedAtomsBAD 2] [lindex $selV::pickedAtomsBAD 3] cyan]
		set mem2 [selV::cylinder [lindex $selV::pickedAtomsBAD 1] [lindex $selV::pickedAtomsBAD 2] cyan]
		
		
		set selV::graphicsID [lappend selV::graphicsID "$mem $mem2"]
	}
	
	
	
	}
}



proc selV::strictformat {fmt value} {
    set f [format $fmt $value]
    regexp {%(\d+)} $fmt -> maxwidth
    if {[string length $f] > $maxwidth} {
        return [string repeat * $maxwidth]
    } else {
        return $f
    }
}


proc selV::sphere {selection color} {	
	set coordinates [[atomselect top "index $selection"] get {x y z}]
	
	# Draw a circle around the coordinate
	draw color $color
	draw material Transparent
	set a [graphics [molinfo top] sphere "[lindex $coordinates 0] [lindex $coordinates 1] [lindex $coordinates 2]" radius 0.9 resolution 25]
	
	return  $a
	
}


proc selV::line {selection0 selection1 color } {

	set coordinates0 [[atomselect top "index $selection0"] get {x y z}]
	set coordinates1 [[atomselect top "index $selection1"] get {x y z}]
	
	# Draw line
	draw color $color
	set a [graphics [molinfo top] line "[lindex $coordinates0 0] [lindex $coordinates0 1] [lindex $coordinates0 2]" "[lindex $coordinates1 0] [lindex $coordinates1 1] [lindex $coordinates1 2]" width 5 style dashed]
	
	# Add text
	#set b [graphics 0 text "[lindex $coordinates0 0] [lindex $coordinates0 1] [lindex $coordinates0 2]" "$value Angstroms"]
	
	return  "$a"


}


proc selV::triangle {selection0 selection1 selection2 color } {
	set coordinates0 [[atomselect top "index $selection0"] get {x y z}]
	set coordinates1 [[atomselect top "index $selection1"] get {x y z}]
	set coordinates2 [[atomselect top "index $selection2"] get {x y z}]

	
	# Draw line
	
	draw color $color
	set a [graphics [molinfo top] triangle "[lindex $coordinates0 0] [lindex $coordinates0 1] [lindex $coordinates0 2]" "[lindex $coordinates1 0] [lindex $coordinates1 1] [lindex $coordinates1 2]" "[lindex $coordinates2 0] [lindex $coordinates2 1] [lindex $coordinates2 2]"]
	
	# Add text
	#set b [graphics [molinfo top] text "[lindex $coordinates1 0] [lindex $coordinates1 1] [lindex $coordinates1 2]" "$value degrees"]
	
	return  "$a"
}


proc selV::cylinder {selection0 selection1 color} {
	set coordinates0 [[atomselect top "index $selection0"] get {x y z}]
	set coordinates1 [[atomselect top "index $selection1"] get {x y z}]

	# Draw
	
	draw color $color
	set a [graphics [molinfo top] cylinder "[lindex $coordinates0 0] [lindex $coordinates0 1] [lindex $coordinates0 2]" "[lindex $coordinates1 0] [lindex $coordinates1 1] [lindex $coordinates1 2]"  radius 0.5 resolution 50]
	
	# Add graphics that will be deleted
	return  $a
	
}

