#include <iostream>
#include <module2/module.hpp>

int main(int argc, char* av[])
{
  std::cout << "Module 2-a: " << CPM_MODULE_2_NS::module2Function(67, 91) << std::endl;
  return 0;
}
