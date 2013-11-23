#include <iostream>
#include "module1/module.hpp"
#include "central/module.hpp"

int main(int argc, char* av[])
{
  CPM_E1M1_GOOFY_NS::E1M1ExportedStruct myStruct;
  myStruct.num1 = 10;
  myStruct.num2 = 20;

  CPM_CENTRAL_EXP_NS::CentralExportedClass myClass1;
  myClass1.num1 = 1;
  myClass1.num2 = 2;
  myClass1.str = "myClass1";

  CPM_CENTRAL_EXP_NS::CentralExportedClass myClass2;
  myClass2.num1 = 4;
  myClass2.num2 = 8;
  myClass2.str = "myClass2";

  CPM_CENTRAL_EXP_NS::CentralExportedClass myClass3;
  myClass2.num1 = 16;
  myClass2.num2 = 32;
  myClass2.str = "myClass3";

  std::cout << "Module 1  : " << CPM_MODULE_1_NS::module1Function(myStruct) << std::endl;
  std::cout << "Central   : " << CPM_CENTRAL_NS::centralFunction(myClass2) << std::endl;
  return 0;
}
