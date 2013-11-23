#ifndef E1M1_H
#define E1M1_H

#include <string>

namespace CPM_E1M1_NS {

struct E1M1ExportedStruct
{
  int num1;
  int num2;
};

std::string e1m1Function(const E1M1ExportedStruct& myStruct);

} // namespace CPM_E1M1_NS 

#endif

