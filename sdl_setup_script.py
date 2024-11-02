import os
import shutil
import zipfile
import urllib.request

# project directory
SDL_URL = "https://www.libsdl.org/release/SDL2-devel-2.26.0-mingw.zip"
SDL_ZIP = "SDL2.zip"
PROJECT_DIR = "my_sdl_project"

def download_file(url, filename):
    if not os.path.exists(filename):
        print(f"Downloading {filename}...")
        urllib.request.urlretrieve(url, filename)
    else:
        print(f"{filename} already downloaded.")

def download_sdl():
    download_file(SDL_URL, SDL_ZIP)

def extract_and_rename_sdl():
    if not os.path.exists("SDL2"):
        with zipfile.ZipFile(SDL_ZIP, 'r') as zip_ref:
            zip_ref.extractall(".")
        
        extracted_folder = next((name for name in os.listdir(".") if name.startswith("SDL2-") and os.path.isdir(name)), None)
        if extracted_folder:
            os.rename(extracted_folder, "SDL2")
    else:
        print("SDL already extracted and renamed.")
    
    # # Delete SDL2.zip after extraction
    # if os.path.exists(SDL_ZIP):
    #     os.remove(SDL_ZIP)
    #     print(f"{SDL_ZIP} has been deleted after extraction.")

def setup_project():
    sdl_folder = "i686-w64-mingw32"

    # paths for include, lib, and DLL
    sdl_include = os.path.join("SDL2", sdl_folder, "include")
    sdl_lib = os.path.join("SDL2", sdl_folder, "lib")
    sdl_dll = os.path.join("SDL2", sdl_folder, "bin", "SDL2.dll")

    os.makedirs(PROJECT_DIR, exist_ok=True)
    shutil.copytree(sdl_include, os.path.join(PROJECT_DIR, "include"), dirs_exist_ok=True)
    shutil.copytree(sdl_lib, os.path.join(PROJECT_DIR, "lib"), dirs_exist_ok=True)
    shutil.copy(sdl_dll, PROJECT_DIR)

    # Create main.cpp with SDL code
    with open(os.path.join(PROJECT_DIR, "main.cpp"), "w") as f:
        f.write("""#include <SDL.h>
#include <iostream>

int main(int argc, char* argv[]) {
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        std::cerr << "SDL could not initialize! SDL_Error: " << SDL_GetError() << std::endl;
        return 1;
    }
    std::cout << "SDL Initialized!" << std::endl;

    SDL_Window* window = SDL_CreateWindow("SDL Screen", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 800, 600, SDL_WINDOW_SHOWN);
    if (window == nullptr) {
        std::cerr << "Window could not be created! SDL_Error: " << SDL_GetError() << std::endl;
        SDL_Quit();
        return 1;
    }

    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    if (renderer == nullptr) {
        std::cerr << "Renderer could not be created! SDL_Error: " << SDL_GetError() << std::endl;
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 1;
    }

    bool isRunning = true;
    SDL_Event e;
    while (isRunning) {
        while (SDL_PollEvent(&e) != 0) {
            if (e.type == SDL_QUIT) {
                isRunning = false;
            }
        }

        SDL_SetRenderDrawColor(renderer, 50, 50, 50, 255);
        SDL_RenderClear(renderer);
        SDL_RenderPresent(renderer);
    }

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();

    return 0;
}
""")

    # Create main.c with SDL code
    with open(os.path.join(PROJECT_DIR, "main.c"), "w") as f:
        f.write("""#include <SDL.h>
#include <stdio.h>

int main(int argc, char* argv[]) {
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        printf("SDL could not initialize! SDL_Error: %s\\n", SDL_GetError());
        return 1;
    }
    printf("SDL Initialized!\\n");

    SDL_Window* window = SDL_CreateWindow("SDL Screen", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 800, 600, SDL_WINDOW_SHOWN);
    if (window == NULL) {
        printf("Window could not be created! SDL_Error: %s\\n", SDL_GetError());
        SDL_Quit();
        return 1;
    }

    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    if (renderer == NULL) {
        printf("Renderer could not be created! SDL_Error: %s\\n", SDL_GetError());
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 1;
    }

    int isRunning = 1;
    SDL_Event e;
    while (isRunning) {
        while (SDL_PollEvent(&e) != 0) {
            if (e.type == SDL_QUIT) {
                isRunning = 0;
            }
        }

        SDL_SetRenderDrawColor(renderer, 50, 50, 50, 255);
        SDL_RenderClear(renderer);
        SDL_RenderPresent(renderer);
    }

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();

    return 0;
}
""")

    # Create Makefile
    with open(os.path.join(PROJECT_DIR, "Makefile"), "w") as f:
        f.write("""all:
	g++ -Iinclude/sdl2 -Llib -o main_cpp main.cpp -lmingw32 -lSDL2main -lSDL2
	gcc -Iinclude/sdl2 -Llib -o main_c main.c -lmingw32 -lSDL2main -lSDL2""")

    print("Project setup complete.")

if __name__ == "__main__":
    download_sdl()
    extract_and_rename_sdl()
    setup_project()
