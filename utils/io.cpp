#include <iostream>
#include <fstream>
#include <string>

int main() {
    // Open the pseudo-terminal files for reading and writing
    std::ofstream input("/tmp/sim_stdin");
    // std::ofstream output("/tmp/sim_stdout");

    if (!input.is_open()) {
        std::cerr << "Error opening stdin files." << std::endl;
        return 1;
    }

    std::string line;
    std::cout << ">> ";
    fflush(stdout);
    while (std::getline(std::cin, line)) {
        // Process the input as needed
        // For this example, we'll just write it back to the output
        std::cout << "A" << std::endl;
        input << line << std::endl;
        std::cout << "Send :" << line << std::endl;
        std::cout << ">> ";
        fflush(stdout);
    }

    // Close the files
    input.close();

    return 0;
}