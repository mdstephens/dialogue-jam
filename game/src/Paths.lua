local Paths = {}

-- Fonts
Paths.Fonts = {
    MainFont = "assets/fonts/x14y24pxHeadUpDaisy.ttf"
}

-- Shaders
Paths.Shaders = {
    Starfield = "assets/shaders/starfield.glsl"
}

-- Audio
Paths.Audio = {
    CardSpawned = "assets/audio/CardSpawned.mp3",
    MainTheme = "assets/audio/MainTheme.mp3",
    PlayStarted = "assets/audio/PlayStarted.mp3"
}

-- CSV Files
Paths.CSV = {
    Cards = "assets/csv/Cards.csv",
    Dialogue = "assets/csv/Dialogue.csv"
}

Paths.Lib = {
    Moonshine = "lib/moonshine",
    LOVElyTree = "LOVElyTree",
    LOVElyTreeNode = "LOVElyTree/node",
    LOVElyTreeRenderer = "LOVElyTree.tree_render",
}

Paths.SRC = {
    CSVReader = "src/CSVReader",
    DialogueTree = "src/DialogueTree",
    DropZone = "src/DropZone",
    MainMenu = "src/MainMenu",
    TextCard = "src/TextCard"
}

return Paths