# Makefile

# directory configuration

# root directory of asset files
ASSETS_ROOT_DIR=assets

# root directory of source files
SOURCE_ROOT_DIR=src

# root directory for build files
BUILD_ROOT_DIR=build

# directory for compiled object files
OBJECT_ROOT_DIR=$(BUILD_ROOT_DIR)/obj

# directory for library file
LIBRARY_ROOT_DIR=lib

# directory for the runtime output
RUNTIME_ROOT_DIR=bin

# distribution root directory
DIST_ROOT_DIR=dist

# directory for macOS bundle
BUNDLE_ROOT_DIR=$(DIST_ROOT_DIR)/macos-arm64

# output configuration
LIBRARY_OUT=$(LIBRARY_ROOT_DIR)/libengine.a
EXECUTABLE_OUT=$(RUNTIME_ROOT_DIR)/gamebin

# macOS app bundle configuration

# CFBundleIdentifier - uniquely identifies the bundle. The string should also be in reverse-DNS format.
BUNDLE_APP_ID=games.sfmlstarter

# CFBundleDisplayName - specifies the display name of the bundle, visible to users and used by Siri.
BUNDLE_DISPLAY_NAME=SFML Starter

# CFBundleSpokenName - contains a suitable replacement for the app name when performing text-to-speech operations.
BUNDLE_SPOKEN_NAME=S F M L Starter

# CFBundleName - specifies the short name of the bundle. This name should be less than 16 characters long.
BUNDLE_NAME=SFMLStarter

# CFBundleShortVersionString - specifies the release version number of the bundle, which identifies a released iteration of the app.
# The release version number is a string composed of three period-separated integers. 
# The first integer represents major revision to the app, such as a revision that implements new features or major changes. 
# The second integer denotes a revision that implements less prominent features. 
# The third integer represents a maintenance release revision.
BUNDLE_SHORT_VERSION=1.0.0

# CFBundleVersion - specifies the build version number of the bundle,
BUNDLE_VERSION=1

# CFBundleExecutable - identifies the name of the bundle’s main executable file.
BUNDLE_EXECUTABLE_NAME=launcher

# bundle.app location
BUNDLE_DIR=$(BUNDLE_ROOT_DIR)/$(BUNDLE_NAME).app

# bundle.app executable location
BUNDLE_OUT_DIR=$(BUNDLE_DIR)/Contents/MacOS
BUNDLE_OUT=$(BUNDLE_OUT_DIR)/$(BUNDLE_EXECUTABLE_NAME)
BUNDLE_RES_DIR=$(BUNDLE_DIR)/Contents/Resources
BUNDLE_PLIST=$(BUNDLE_DIR)/Contents/Info.plist

# compiler configuration
CC=clang++

# SFML library flags
SFML_CFLAGS=$(shell pkg-config sfml-graphics sfml-window sfml-system --cflags)
SFML_LDFLAGS=$(shell pkg-config sfml-graphics sfml-window sfml-system --libs)

ENGINE_SOURCES=$(shell find $(SOURCE_ROOT_DIR)/engine -name "*.cpp")
ENGINE_HEADERS=$(shell find $(SOURCE_ROOT_DIR)/engine -name "*.h")
ENGINE_OBJECTS=$(patsubst $(SOURCE_ROOT_DIR)/%.cpp,$(OBJECT_ROOT_DIR)/%.o,$(ENGINE_SOURCES))

GAME_SOURCES=$(shell find $(SOURCE_ROOT_DIR)/game -name "*.cpp")
GAME_OBJECTS=$(patsubst $(SOURCE_ROOT_DIR)/%.cpp,$(OBJECT_ROOT_DIR)/%.o,$(GAME_SOURCES))

CFLAGS=-DSTATIC_SFML $(SFML_CFLAGS) $(addprefix -I,$(wildcard $(SOURCE_ROOT_DIR)/**)) -Wall -Wextra -Wpedantic -std=c++17 -O3
LDFLAGS=$(SFML_LDFLAGS)

# phony targets
.PHONY: all info binfo dirs assets engine game bundle plist clean

# special case - first target in Makefile is executed when "make" is run without a target
all: dirs assets engine game

# echo the configuration that will be used
info:
	@echo ASSETS_ROOT_DIR: $(ASSETS_ROOT_DIR)
	@echo SOURCE_ROOT_DIR: $(SOURCE_ROOT_DIR)
	@echo BUILD_ROOT_DIR: $(BUILD_ROOT_DIR)
	@echo OBJECT_ROOT_DIR: $(OBJECT_ROOT_DIR)
	@echo LIBRARY_ROOT_DIR: $(LIBRARY_ROOT_DIR)
	@echo BUNDLE_ROOT_DIR: $(BUNDLE_ROOT_DIR)
	@echo RUNTIME_ROOT_DIR: $(RUNTIME_ROOT_DIR)
	@echo LIBRARY_OUT: $(LIBRARY_OUT)
	@echo EXECUTABLE_OUT: $(EXECUTABLE_OUT)
	@echo SFML_CFLAGS: $(SFML_CFLAGS)
	@echo SFML_LDFLAGS: $(SFML_LDFLAGS)
	@echo ENGINE_SOURCES: $(ENGINE_SOURCES)
	@echo ENGINE_OBJECTS: $(ENGINE_OBJECTS)
	@echo GAME_SOURCES: $(GAME_SOURCES)
	@echo GAME_OBJECTS: $(GAME_OBJECTS)
	@echo CFLAGS: $(CFLAGS)
	@echo LDFLAGS: $(LDFLAGS)

# echo the macOS bundle configuration
binfo:
	@echo "BUNDLE_ROOT_DIR: $(BUNDLE_ROOT_DIR)"
	@echo "     BUNDLE_DIR: $(BUNDLE_DIR)"
	@echo "     BUNDLE_OUT: $(BUNDLE_OUT)"
	@echo " BUNDLE_RES_DIR: $(BUNDLE_RES_DIR)"
	@echo ""
	@echo Info.plist Configuration $(BUNDLE_PLIST)
	@echo ""
	@echo "        CFBundleIdentifier: $(BUNDLE_APP_ID)"
	@echo "       CFBundleDisplayName: $(BUNDLE_DISPLAY_NAME)"
	@echo "        CFBundleSpokenName: $(BUNDLE_SPOKEN_NAME)"
	@echo "              CFBundleName: $(BUNDLE_NAME)"
	@echo "CFBundleShortVersionString: $(BUNDLE_SHORT_VERSION)"
	@echo "           CFBundleVersion: $(BUNDLE_VERSION)"
	@echo "        CFBundleExecutable: $(BUNDLE_EXECUTABLE_NAME)"

# make the directories if they do not exist
dirs:
	@mkdir -p $(BUILD_ROOT_DIR) $(LIBRARY_ROOT_DIR) $(RUNTIME_ROOT_DIR)

# copy the assets from the assets directory into the runtime output directory
assets:
	@cp -r $(ASSETS_ROOT_DIR)/* $(RUNTIME_ROOT_DIR)

# make the engine library
engine: $(LIBRARY_OUT)
	@cp $(ENGINE_HEADERS) $(LIBRARY_ROOT_DIR)

# make the game executable
game: $(EXECUTABLE_OUT) assets

ifeq ($(shell uname -s),Darwin)
plist:
	@echo "\x1b[32mProducing: $(BUNDLE_PLIST)\x1b[0m"
	@mkdir -p $(BUNDLE_OUT_DIR)
	@rm -f $(BUNDLE_PLIST)
	@echo "3C3F786D6C2076657273696F6E3D22312E302220656E636F64696E673D225554462D38223F3E0D0A3C21444F435459504520706C697374205055424C494320222D2F2F4170706C652F2F44544420504C49535420312E302F2F454E222022687474703A2F2F7777772E6170706C652E636F6D2F445444732F50726F70657274794C6973742D312E302E647464223E0D0A3C706C6973742076657273696F6E3D22312E30223E0D0A093C646963743E0D0A093C2F646963743E0D0A3C2F706C6973743E0D0A" | xxd -r -p > $(BUNDLE_PLIST)
	@/usr/libexec/PlistBuddy -c 'Add :CFBundleIdentifier string $(BUNDLE_APP_ID)' $(BUNDLE_PLIST) 2>/dev/null
	@/usr/libexec/PlistBuddy -c 'Add :CFBundleDisplayName string $(BUNDLE_DISPLAY_NAME)' $(BUNDLE_PLIST) 2>/dev/null
	@/usr/libexec/PlistBuddy -c 'Add :CFBundleSpokenName string $(BUNDLE_SPOKEN_NAME)' $(BUNDLE_PLIST) 2>/dev/null
	@/usr/libexec/PlistBuddy -c 'Add :CFBundleName string $(BUNDLE_NAME)' $(BUNDLE_PLIST) 2>/dev/null
	@/usr/libexec/PlistBuddy -c 'Add :CFBundleShortVersionString string $(BUNDLE_SHORT_VERSION)' $(BUNDLE_PLIST) 2>/dev/null
	@/usr/libexec/PlistBuddy -c 'Add :CFBundleVersion string $(BUNDLE_VERSION)' $(BUNDLE_PLIST) 2>/dev/null
	@/usr/libexec/PlistBuddy -c 'Add :CFBundleExecutable string $(BUNDLE_EXECUTABLE_NAME)' $(BUNDLE_PLIST) 2>/dev/null
else
plist:
	@echo "macOS tools are not available on this system"
endif

# make the macOS application bundle
ifeq ($(shell uname -s),Darwin)
bundle: game plist
	@echo "\x1b[32mProducing: $(BUNDLE_OUT)\x1b[0m"
	@mkdir -p $(BUNDLE_RES_DIR)
	@cp $(EXECUTABLE_OUT) $(BUNDLE_OUT)
	@echo "\x1b[32mProducing: $(BUNDLE_RES_DIR)/*\x1b[0m"
	@cp -r $(ASSETS_ROOT_DIR)/* $(BUNDLE_RES_DIR)
else
bundle:
	@echo "$(BUNDLE_OUT) can only be made on macOS"
endif

# clean all output
clean:
	@echo "\x1b[32mCleaning: $(BUILD_ROOT_DIR)\x1b[0m"
	@echo "\x1b[32mCleaning: $(LIBRARY_ROOT_DIR)\x1b[0m"
	@echo "\x1b[32mCleaning: $(DIST_ROOT_DIR)\x1b[0m"
	@echo "\x1b[32mCleaning: $(RUNTIME_ROOT_DIR)\x1b[0m"
	@rm -rf $(BUILD_ROOT_DIR) $(LIBRARY_ROOT_DIR) $(DIST_ROOT_DIR) $(RUNTIME_ROOT_DIR)

# producer targets

# produce the main executable binary
$(EXECUTABLE_OUT): $(LIBRARY_OUT) $(GAME_OBJECTS)
	@echo "\x1b[32mProducing: $(EXECUTABLE_OUT)\x1b[0m"
	@mkdir -p $(@D)
	@$(CC) $(GAME_OBJECTS) -L$(LIBRARY_ROOT_DIR) -lengine $(LDFLAGS) -o $@
	@$(CC) $(LDFLAGS) $^ -o $@

# produce the engine library
$(LIBRARY_OUT): $(ENGINE_OBJECTS)
	@echo "\x1b[32mProducing: $(LIBRARY_OUT)\x1b[0m"
	@mkdir -p $(@D)
	@ar rcs $@ $^
	@ranlib $@

# compile the source files into objects
$(OBJECT_ROOT_DIR)/%.o: $(SOURCE_ROOT_DIR)/%.cpp
	@mkdir -p $(@D)
	@$(CC) $(CFLAGS) -MMD -c $< -o $@

-include $(ENGINE_OBJECTS:.o=.d)
-include $(GAME_OBJECTS:.o=.d)