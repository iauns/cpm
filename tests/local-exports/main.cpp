#include <iostream>
#include "module1/module.hpp"
#include "module2/module.hpp"

int main(int argc, char* av[])
{
  CPM_E1M1_NS::E1M1ExportedStruct myStruct;
  myStruct.num1 = 49;
  myStruct.num2 = 152;

  std::cout << CPM_MODULE1_NS::module1Function(myStruct) << std::endl;
  std::cout << CPM_MODULE2_NS::module2Function(67, 91) << std::endl;
  return 0;
}
