#pragma once
#include "geommath.hpp"
#include "Polyhedron.hpp"

namespace newbieGE
{
class QuickHull
{
public:
    QuickHull() = default;
    ~QuickHull() = default;
    bool Iterate(Polyhedron &hull, PointSet &point_set);

protected:
    bool Init(Polyhedron &hull, PointSet &point_set);
    void IterateHull(Polyhedron &hull, PointSet &point_set);
    void AssignPointsToFaces(const Polyhedron &hull, PointSet &point_set, PointPtr &far_point, FaceList &faces);

protected:
    PointPtr center_of_tetrahedron;
};
} // namespace newbieGE
