#include <iostream>
#include "cpm-test-01/module.hpp"
#include "module1/module.hpp"
#include "module2/module.hpp"

int main(int argc, char* av[])
{
  std::cout << CPM_TEST_01_NS::test01Function("Direct call:", 12, 51) << std::endl;
  std::cout << CPM_MODULE1_NS::module1Function(67) << std::endl;
  std::cout << CPM_MODULE2_NS::module2Function(67, 91) << std::endl;
  return 0;
}
