#include <iostream>
#include "cpm-test-01/module.hpp"

int main(int argc, char* av[])
{
  std::cout << CPM_TEST_01_NS::test01Function("Direct call:") << std::endl;
  return 0;
}
