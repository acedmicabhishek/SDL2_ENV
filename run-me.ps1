# Define paths and constants
$SDL_FOLDER = "SDL2"
$PROJECT_DIR = "my_sdl_project"
$MinGWSource = ".\MinGW"
$MinGWTarget = "C:/MinGW"
$SDL_ZIP = "SDL2.zip"

# Step 1: Copy MinGW (baked in gnu) to C:\
Write-Host "Copying MinGW to C:\..."
if (Test-Path -Path $MinGWSource) {
    Copy-Item -Path $MinGWSource -Destination $MinGWTarget -Recurse -Force
    Write-Host "MinGW copied successfully."
} else {
    Write-Host "Error: MinGW folder not found in the current directory."
    exit 1
}

# Step 2: Set the environment variable for MinGW
Write-Host "Setting up environment variable for MinGW..."
$env:Path += ";C:/MinGW/bin"
Write-Host "Environment variable set successfully."

function Extract-And-Rename-SDL() {
    if (-not (Test-Path $SDL_FOLDER)) {
        Write-Host "Extracting $SDL_ZIP..."
        if (Test-Path $SDL_ZIP) {
            Expand-Archive -Path $SDL_ZIP -DestinationPath "."

            $ExtractedFolder = Get-ChildItem -Directory | Where-Object { $_.Name -like "SDL2-*" }
            if ($ExtractedFolder) {
                Rename-Item -Path $ExtractedFolder.FullName -NewName $SDL_FOLDER
                Write-Host "Renamed folder to $SDL_FOLDER."
            } else {
                Write-Host "Error: Could not find extracted SDL2 folder."
                exit 1
            }
        } else {
            Write-Host "Error: SDL2.zip not found in the directory."
            exit 1
        }
    } else {
        Write-Host "SDL folder already exists."
    }
}

function Setup-Project() {
    $SDL_SUBFOLDER = "i686-w64-mingw32"
    $SDL_INCLUDE = Join-Path -Path $SDL_FOLDER -ChildPath "$SDL_SUBFOLDER\include"
    $SDL_LIB = Join-Path -Path $SDL_FOLDER -ChildPath "$SDL_SUBFOLDER\lib"
    $SDL_DLL = Join-Path -Path $SDL_FOLDER -ChildPath "$SDL_SUBFOLDER\bin\SDL2.dll"

    # Create project directory and subdirectories
    Write-Host "Setting up project directory..."
    New-Item -ItemType Directory -Path $PROJECT_DIR -Force | Out-Null
    Copy-Item -Path $SDL_INCLUDE -Destination (Join-Path $PROJECT_DIR "include") -Recurse -Force
    Copy-Item -Path $SDL_LIB -Destination (Join-Path $PROJECT_DIR "lib") -Recurse -Force
    Copy-Item -Path $SDL_DLL -Destination $PROJECT_DIR -Force

    # Generate main.cpp
    $MainCppContent = @"
#include <SDL.h>
#include <iostream>
#include <cmath>

// Function to round off the pixel values
int round(float n) {
    if (n - (int)n < 0.5)
        return (int)n;
    return (int)(n + 1);
}

// Function for DDA line generation
void drawDDALine(SDL_Renderer* renderer, int x0, int y0, int x1, int y1) {
    // Calculate dx and dy
    int dx = x1 - x0;
    int dy = y1 - y0;

    int steps;
    // If dx > dy, we take step as dx, else we take step as dy to draw the complete line
    if (std::abs(dx) > std::abs(dy)) {
        steps = std::abs(dx);
    } else {
        steps = std::abs(dy);
    }

    // Calculate x-increment and y-increment for each step
    float xIncr = static_cast<float>(dx) / steps;
    float yIncr = static_cast<float>(dy) / steps;

    // Initial points for x and y
    float x = x0;
    float y = y0;

    for (int i = 0; i <= steps; i++) {
        // Draw the pixel at the calculated (x, y)
        SDL_RenderDrawPoint(renderer, round(x), round(y));

        // Increment x and y
        x += xIncr;
        y += yIncr;
    }
}

int main(int argc, char* argv[]) {
    // Initialize SDL
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        std::cerr << "SDL could not initialize! SDL_Error: " << SDL_GetError() << std::endl;
        return 1;
    }
    std::cout << "SDL Initialized!" << std::endl;

    // Create a window
    SDL_Window* window = SDL_CreateWindow("DDA Line Algorithm", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 800, 600, SDL_WINDOW_SHOWN);
    if (window == nullptr) {
        std::cerr << "Window could not be created! SDL_Error: " << SDL_GetError() << std::endl;
        SDL_Quit();
        return 1;
    }

    // Create a renderer
    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    if (renderer == nullptr) {
        std::cerr << "Renderer could not be created! SDL_Error: " << SDL_GetError() << std::endl;
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 1;
    }

    // Set the background color (dark gray)
    SDL_SetRenderDrawColor(renderer, 50, 50, 50, 255);
    SDL_RenderClear(renderer);

    // Set the line color (white)
    SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);




        // Main function call to Draw a line using DDA
    drawDDALine(renderer, 100, 100, 700, 500);





    // Present the renderer to the screen
    SDL_RenderPresent(renderer);

    // Wait for the user to close the window
    SDL_Event e;
    bool isRunning = true;
    while (isRunning) {
        while (SDL_PollEvent(&e) != 0) {
            if (e.type == SDL_QUIT) {
                isRunning = false;
            }
        }
    }

    // Clean up and quit
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();

    return 0;
}
"@
    Set-Content -Path (Join-Path $PROJECT_DIR "main.cpp") -Value $MainCppContent

    # Generate main.c
    $MainCContent = @"
#include <SDL.h>
#include <stdio.h>
#include <math.h>

// Function to round off the pixels
int roundf_custom(float n) {
    if (n - (int)n < 0.5) 
        return (int)n;
    return (int)(n + 1);
}

// Function for DDA line generation
void DDALine(SDL_Renderer *renderer, int x0, int y0, int x1, int y1) {
    // Calculate dx and dy
    int dx = x1 - x0;
    int dy = y1 - y0;
    
    int steps;
    
    // Find the number of steps required for the line
    if (abs(dx) > abs(dy))
        steps = abs(dx);
    else
        steps = abs(dy);
    
    // Calculate x-increment and y-increment for each step
    float x_incr = (float)dx / steps;
    float y_incr = (float)dy / steps;
    
    // Start at (x0, y0)
    float x = x0;
    float y = y0;
    
    for (int i = 0; i <= steps; i++) {
        // Round the floating point values to the nearest integer
        int px = roundf_custom(x);
        int py = roundf_custom(y);
        
        // Set the pixel color to white and draw the point
        SDL_RenderDrawPoint(renderer, px, py);
        
        // Increment x and y
        x += x_incr;
        y += y_incr;
    }
}

int main(int argc, char* argv[]) {
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        printf("SDL could not initialize! SDL_Error: %s\n", SDL_GetError());
        return 1;
    }
    printf("SDL Initialized!\n");

    SDL_Window* window = SDL_CreateWindow("SDL Screen", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 800, 600, SDL_WINDOW_SHOWN);
    if (window == NULL) {
        printf("Window could not be created! SDL_Error: %s\n", SDL_GetError());
        SDL_Quit();
        return 1;
    }

    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    if (renderer == NULL) {
        printf("Renderer could not be created! SDL_Error: %s\n", SDL_GetError());
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

        // Set background color to dark gray
        SDL_SetRenderDrawColor(renderer, 50, 50, 50, 255);
        SDL_RenderClear(renderer);

        // Set line color to white
        SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
        
        // Draw a line using DDA algorithm (example line from (100, 100) to (700, 500))
        DDALine(renderer, 100, 100, 700, 500);

        // Update the screen with rendered content
        SDL_RenderPresent(renderer);
    }

    // Clean up and close
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();

    return 0;
}
"@
    Set-Content -Path (Join-Path $PROJECT_DIR "main.c") -Value $MainCContent

    # Generate Makefile
    # this part suck some times it ends up creating spaces and i hate it why the same code works and sometimes it doesnt 
    # just kys
    $MakefileContent = @"
all:
	g++ -Iinclude/sdl2 -Llib -o main_cpp main.cpp -lmingw32 -lSDL2main -lSDL2
	gcc -Iinclude/sdl2 -Llib -o main_c main.c -lmingw32 -lSDL2main -lSDL2
"@
    Set-Content -Path (Join-Path $PROJECT_DIR "Makefile") -Value $MakefileContent

    Write-Host "Project setup complete."
}

# Main execution
Extract-And-Rename-SDL
Setup-Project

Write-Host "Setup complete."
