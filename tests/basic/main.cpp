#include <iostream>
#include "module1/module1.hpp"

int main(int argc, char* av[])
{
  std::cout << CPM_MODULE1_NS::module1Function("Test Str") << std::endl;
  return 0;
}
